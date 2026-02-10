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

# Set up environment variables
cp .env.example .env
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
Raw data from API

| Field | Type | Source | Example |
|-------|------|--------|---------|
| `spaceid` | `string` | Inventory API | `"HO108"` |
| `latlng` | `{lat: float, lng: float}` | Inventory API | `{lat: 34.086, lng: -118.294}` |
| `blockface` | `string` | Inventory API | `"800 HELIOTROPE DR"` |
| `rate` | `float` | Inventory API (parsed) | `1.50` ($/hr) |
| `timelimit` | `integer` | Inventory API (parsed) | `360` (minutes) |
| `occupancyStatus` | `enum` | Occupancy API | `"VACANT"` / `"OCCUPIED"` |
| `lastUpdated` | `ISO 8601 string` | Occupancy API | `"2026-01-24T19:03:24"` |

## Computed Fields
After data cleaning, used for scoring

| Field | Type | Derivation |
|-------|------|------------|
| `distanceToDestination` | `float` | `Haversine(meter.latlng, destination.latlng)` in meters |
| `walkTime` | `integer` | `distanceToDestination / 80` (avg walking speed m/min) |
| `estimatedTotalCost` | `float` | `rate × (duration / 60)` |

## Final output (Ranked List)
This is what is displayed on the frontend and should follow the desired logical view

| Field | Type | Example |
|-------|------|---------|
| `spaceid` | `string` | `"HO108"` |
| `addressMeter` | `string` | `"6233 Hollywood Blvd"` |
| `walkTime` | `integer` | `3` (minutes) |
| `rate` | `float` | `2.00` ($/hr) |
| `estimatedTotalCost` | `float` | `6.00` |
| `timelimit` | `integer` | `240` (minutes) |
| `rank` | `integer` | `1` |

## Running Frontend Example
Assuming that you have a Macbook Pro and have XCode installed, simply click open the `cs-125.xcodeproj` file in XCode. 

Once the project is successfully opened, there should be a play button that you can click to boot up the app. 

![User Interface Screenshot](frontend_example.png)
