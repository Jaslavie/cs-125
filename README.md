# cs-125: Petr Parking

## Getting Started

### Prerequisites

- Python 3.11+
- pip

### Setup

```bash
# Clone the repo
git clone https://github.com/Jaslavie/cs-125.git
cd cs-125

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables (see below)
cp .env.example .env
```

### Environment Variables

After copying `.env.example` to `.env`, fill in the two values:

1. **LADOT_APP_TOKEN** — the LADOT meter data is served via the [Socrata SODA API](https://dev.socrata.com/docs/app-tokens.html). 
- To get a token you need to create a free account on [data.lacity.org](https://data.lacity.org)
- Go to your profile → **Developer Settings** → **Create New App Token**
- Paste the generated token after `LADOT_APP_TOKEN=`.
2. **SUPABASE_CONNECTION_STRING** — replace `[PASSWORD]` with the database password. 
- **THE PASSWORD FOR SUPABASE IS PROVIDED IN OUR PROJECT WRITEUP.**

Your .env file should look like this:
```
LADOT_APP_TOKEN=<YOUR_GENERATED_TOKEN>
SUPABASE_CONNECTION_STRING= postgresql://postgres.dveanciavnhmxeruofhc:[PASSWORD_FROM_WRITEUP]@aws-1-us-east-2.pooler.supabase.com:5432/postgres
```
### Running the API Server

```bash
# From project root, with venv activated
uvicorn src.clients.ladot_client:app --reload
```

The server will start at `http://127.0.0.1:8000`

You may also use the /docs extension for a cleaner UI to interact with the API

### API Endpoints

#### Get Nearby Meters
Gets meters within the radius of the target location
```bash
curl -X POST "http://127.0.0.1:8000/ladot-meters" \
  -H "Content-Type: application/json" \
  -d '{"lat": 34.1017, "lon": -118.3261}'
```

Example response:
```json
[
  {
    "spaceid": "HO453",
    "blockface": "1700 VINE ST",
    "metertype": "Single-Space",
    "ratetype": "TOD",
    "raterange": "$1.00 - $4.00",
    "timelimit": "2HR",
    "latlng": {"latitude": "34.102265", "longitude": "-118.326565"}
  }
]
```

#### Get Meter Occupancy
Gets the most recent occupancy status for specified meter IDs
```bash
curl -X POST "http://127.0.0.1:8000/ladot-occupancy" \
  -H "Content-Type: application/json" \
  -d '{"spaceids": ["HO450A", "HO525", "HO453"]}'
```

Example response:
```json
{
  "HO450A": {"occupancystate": "VACANT", "eventtime": "2026-01-24T22:47:08.000"},
  "HO525": {"occupancystate": "UNKNOWN", "eventtime": "2026-01-24T20:59:48.000"},
  "HO453": {"occupancystate": "OCCUPIED", "eventtime": "2026-01-24T17:26:56.000"}
}
```

### Run full retrieval pipeline and get output meters
Returns: List of OutputMeters (formatted as MeterResponse) from full retrieval and ranking pipeline
HTTP endpoint: `/meters/search`

Example response: 
```json
[
  {
    "spaceid": "WV512",
    "address": "10901 LE CONTE AVE",
    "rate_per_hour": 1.5,
    "time_limit_minutes": 120,
    "occupancy": "UNKNOWN",
    "distance_to_destination_meters": 789.0062376194693,
    "walk_time_minutes": 9,
    "estimated_total_cost": 1.5,
    "rank": 1
  },
]
```
---

# Data Model
Datasets:
- "Inventory of all on-street metered parking spaces in the City of Los Angeles" [Link](https://data.lacity.org/Transportation/LADOT-Metered-Parking-Inventory-Policies/s49e-q6j2/about_data)
- "Real-time parking availability at over 5,000 spaces" [Link](https://data.lacity.org/Transportation/LADOT-Parking-Meter-Occupancy/e7h6-4a3e/about_data)

## User Input
User inputed data for each query

| Field | Type | Example | Notes |
|-------|------|---------|-------|
| `targetLocation` | `string` | `"Pantages Theatre"` | Free text, geocoded to lat/lng |
| `currentLocation` | `{lat: float, lng: float}` | `{lat: 34.101, lng: -118.325}` | From device GPS |
| `currentTime` | `ISO 8601 string` | `"2026-01-24T19:00:00"` | Auto-captured |
| `budgetRangePreference` | `category` | `"medium"` | See category mappings below |
| `stayTimePreference` | `category` | `"short"` | See category mappings below |

### Preference Category Mappings
**`budgetRangePreference`** - max total cost user is willing to pay
| Category | USD Range |
|----------|-----------|
| `"low"` | $0 - $10 |
| `"medium"` | $10 - $20 |
| `"high"` | $20 - $50 |

**`stayTimePreference`** - how long user plans to park
| Category | Duration Range |
|----------|----------------|
| `"short"` | 0 - 60 minutes |
| `"medium"` | 60 - 120 minutes |
| `"long"` | 120 - 240 minutes |

## Meter Data

### Raw API Fields

| Field | Type | Source | Example |
|-------|------|--------|---------|
| `spaceid` | `string` | Inventory API | `"HO108"` |
| `blockface` | `string` | Inventory API | `"800 HELIOTROPE DR"` |
| `metertype` | `string` | Inventory API | `"Single-Space"` |
| `ratetype` | `string` | Inventory API | `"TOD"` / `"FLAT"` / `"JUMP"` |
| `raterange` | `string` | Inventory API | `"$2.00 - $3.00"` |
| `timelimit` | `string` | Inventory API | `"2HR"` / `"30MIN"` |
| `latlng` | `{latitude: string, longitude: string}` | Inventory API | `{latitude: "34.086", longitude: "-118.294"}` |
| `occupancystate` | `string` | Occupancy API | `"VACANT"` / `"OCCUPIED"` |
| `eventtime` | `ISO 8601 string` | Occupancy API | `"2026-01-24T19:03:24.000"` |

### Parsed Fields (`CandidateMeter`)

`parsers.clean_data()` converts raw strings into typed values:

| Field | Type | Parsed from | Example |
|-------|------|-------------|---------|
| `spaceid` | `string` | passthrough | `"HO453"` |
| `metertype` | `string` | passthrough | `"Single-Space"` |
| `location` | `Location(lat, lon)` | `latlng` strings → floats | `Location(34.102, -118.326)` |
| `address` | `string` | reverse geocode from lat/lon | `"1700 Vine St, Los Angeles, CA"` |
| `rate_per_hour` | `tuple[float, float]` | `raterange` string | `(2.0, 3.0)` |
| `time_limit_minutes` | `int` | `timelimit` string | `120` |
| `occupancy` | `OccupancyStatus` enum | `occupancystate` string | `VACANT` |
| `occupancy_time` | `datetime | None` | `eventtime` string | `2026-01-24T19:03:24` |

#### Rate parsing rules
| Raw `raterange` | Pattern | Parsed `rate_per_hour` |
|-----------------|---------|----------------------|
| `"$4.00"` | FLAT | `(4.0, 4.0)` |
| `"$2.00 - $3.00"` | TOD (time-of-day range) | `(2.0, 3.0)` |
| `"$1.5/H - $6/10H"` | JUMP (escalating) | `(1.5, 6.0)` |

#### Time limit parsing rules
| Raw `timelimit` | Parsed `time_limit_minutes` |
|-----------------|---------------------------|
| `"2HR"` | `120` |
| `"30MIN"` | `30` |

## Geohash Inverted Index
Meters are indexed by geohash cell for fast spatial lookup.

- **Key**: geohash string (encodes a ~150m x 150m grid cell)
- **Value**: list of `RawMeterInventory` objects in that cell

```json
{
  "9q5ctr2": [
    {"spaceid": "HO453", "blockface": "1700 VINE ST", ...},
    {"spaceid": "HO454", "blockface": "1701 VINE ST", ...}
  ],
  "9q5ctr3": [
    {"spaceid": "SV881", "blockface": "1400 VINE ST", ...}
  ]
}
```

At query time, we look up the user's cell + 8 neighbors (9 cells total) to find all nearby meters.

## Computed Fields (on `OutputMeter`)
Computed per query in `retrieval.py` — these depend on the user's location and preferences, not the meter itself.

| Field | Type | Derivation |
|-------|------|------------|
| `distance_to_destination_meters` | `float` | `Haversine(meter.location, user.location)` |
| `walk_time_minutes` | `int` | `distance / 80` (avg walking speed m/min) |
| `estimated_total_cost` | `float` | `rate × (stay_time / 60)` |

## Final output (Ranked List)
This is what is displayed on the frontend and should follow the desired logical view

| Field | Type | Example |
|-------|------|---------|
| `spaceid` | `string` | `"HO108"` |
| `address` | `string` | `"6233 Hollywood Blvd"` |
| `rate_per_hour` | `float` | `2.00` ($/hr) |
| `time_limit_minutes` | `int` | `240` (minutes) |
| `occupancy` | `OccupancyStatus` | `VACANT` |
| `walk_time_minutes` | `int` | `3` (minutes) |
| `estimated_total_cost` | `float` | `6.00` |
| `rank` | `int` | `1` |

## Database storage
- Provider: Supabase
- DBMS: Postgresql
- DB stores: List of CandidateMeters (all meters within search radius)

# Evaluations

We evaluate ranking quality by running the ranker against a golden LADOT snapshot (200 real meters near Hollywood & Vine) and scoring each output meter with an independent relevance rubric (0–3 scale based on budget, distance, and time constraints). Five query profiles are tested, including edge cases (LOW/LONG stress test, HIGH/SHORT control).

### Metrics
- **NDCG@K** — are the best meters ranked first? Measures graded ordering quality with position discount
- **MAP@K** — are relevant meters packed at the top without poor ones interleaved?
- **MRR@K** — how quickly does the user see a usable meter? (1/rank of first relevant)
- **Precision@K** — what fraction of the top-K results are actually usable?

### Test files
| File | Purpose |
|------|---------|
| `tests/eval/metrics.py` | Metric functions + eval runner against golden data |
| `tests/eval/golden/meters.json` | Frozen LADOT meter inventory snapshot (200 meters) |
| `tests/eval/golden/occupancy.json` | Frozen LADOT occupancy snapshot (79 records) |
| `tests/test_ranking.py` | Unit tests for scoring components, preference weighting, penalties |
| `tests/test_retrieval.py` | Unit tests for geohash indexing, spatial lookup, pipeline |
| `tests/test_db.py` | API endpoint and database integration tests |

Run the eval suite:
```bash
source venv/bin/activate && python -m pytest tests/eval/metrics.py -s
```

---

## How To Run

End-to-end steps to run the backend and iOS app (including location simulation for the simulator).

### Prerequisites

- **Python 3.11+**
- **pip**
- **macOS**
- **Xcode 26.2** (or compatible version)

### 1. Clone and set up the project

Clone the repo and change into the project directory:

```bash
git clone https://github.com/Jaslavie/cs-125.git
cd cs-125
```

Create and activate a virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
```

Install Python dependencies for the backend:

```bash
pip install -r requirements.txt
```

### 2. Environment variables

Add `LADOT_APP_TOKEN` and `SUPABASE_CONNECTION_STRING` for backend functionality:

```bash
cp .env.example .env
```

Edit `.env` and set your own values:

- **LADOT_APP_TOKEN**
  - Create a free account at [data.lacity.org](https://data.lacity.org).
  - Go to **Profile → Developer Settings → Create New App Token**.
  - Paste the generated token after `LADOT_APP_TOKEN=` in `.env`.

- **SUPABASE_CONNECTION_STRING**
  - Replace `[PASSWORD]` in the connection string with the database password.
  - **The database password is provided in the highlighted text on page one of our submitted final report.**

### 3. Start the backend

From the project root (with your virtual environment activated):

```bash
uvicorn src.api:app --reload --host 0.0.0.0 --port 8000
```

You should see output similar to:

```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [...]
INFO:     Started server process [...]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

If so, the backend is running successfully.

### 4. Open the project in Xcode

1. Open the **Xcode** app on your Mac.
2. Click **Open Existing Project...** (or **File → Open**).
3. In the Finder window, go to the **cs-125** directory.
4. Select **cs-125.xcodeproj** and click **Open**.

You should see the Xcode workspace with the project loaded (e.g. **cs-125** in the toolbar and the project navigator on the left).

### 5. Simulate the user’s current location

The app uses the device location for ranking and route display. In the simulator, you need to provide a simulated location.

1. In the Xcode menu bar, choose **Product → Scheme → Edit Scheme...**.
2. In the left sidebar, select **Run** (under the **Debug** group).
3. Open the **Options** tab.
4. Under **Default Location**, open the dropdown and choose **Add GPX File to Project...**.
5. In the Finder window, go to the **cs-125** directory and select **LA.gpx**. Click **Add**.
6. Close the scheme editor.

### 6. Run the app

Click the **Play** (Run) button in the top-left of the Xcode window (or press **⌃R**).

After startup, the iOS simulator should open and you should see the **PetrParker** login screen (username, password, Login, and Create Account). If you are starting the app for the first time and have not left the simulator while logged in, you will land on this login screen.