# cs-125: Petr Parking

## Data Model
Datasets:
-"Inventory of all on-street metered parking spaces in the City of Los Angeles" [Link](https://data.lacity.org/Transportation/LADOT-Metered-Parking-Inventory-Policies/s49e-q6j2/about_data)
-"Real-time parking availability at over 5,000 spaces" [Link](https://data.lacity.org/Transportation/LADOT-Parking-Meter-Occupancy/e7h6-4a3e/about_data)

### User Input (Per Query)

| Field | Type | Example | Notes |
|-------|------|---------|-------|
| `targetLocation` | `string` | `"Pantages Theatre"` | Free text, geocoded to lat/lng |
| `currentLocation` | `{lat: float, lng: float}` | `{lat: 34.101, lng: -118.325}` | From device GPS |
| `currentTime` | `ISO 8601 string` | `"2026-01-24T19:00:00"` | Auto-captured |
| `budgetRangePreference` | `category` | `"medium"` → $10.00 - $20.00 | Affects scoring weights. Budget in USD |
| `walkingDistancePreference` | `category` | `"close"` → x-y meters walk | Affects scoring weights. Distance in meters |
| `stayTimePreference` | `category` | `"long"` → x-y minutes | Affects scoring weights. Time in minutes |

### Meter Data (Retrieved)

Combined from Dataset 1 (Inventory) + Dataset 2 (Occupancy).

| Field | Type | Source | Example |
|-------|------|--------|---------|
| `spaceid` | `string` | Inventory API | `"HO108"` |
| `latlng` | `{lat: float, lng: float}` | Inventory API | `{lat: 34.086, lng: -118.294}` |
| `blockface` | `string` | Inventory API | `"800 HELIOTROPE DR"` |
| `rate` | `float` | Inventory API (parsed) | `1.50` ($/hr) |
| `timelimit` | `integer` | Inventory API (parsed) | `360` (minutes) |
| `occupancyStatus` | `enum` | Occupancy API | `"VACANT"` / `"OCCUPIED"` |
| `lastUpdated` | `ISO 8601 string` | Occupancy API | `"2026-01-24T19:03:24"` |

### Computed Fields (Scoring)

| Field | Type | Derivation |
|-------|------|------------|
| `distanceToDestination` | `float` | `Haversine(meter.latlng, destination.latlng)` in meters |
| `walkTime` | `integer` | `distanceToDestination / 80` (avg walking speed m/min) |
| `estimatedTotalCost` | `float` | `rate × (duration / 60)` |
| `score` | `float` | Weighted combo of distance, cost, user prefs |

### Output (Ranked List)

| Field | Type | Example |
|-------|------|---------|
| `spaceid` | `string` | `"HO108"` |
| `address` | `string` | `"6233 Hollywood Blvd"` |
| `walkTime` | `integer` | `3` (minutes) |
| `rate` | `float` | `2.00` ($/hr) |
| `estimatedTotalCost` | `float` | `6.00` |
| `timelimit` | `integer` | `240` (minutes) |
| `rank` | `integer` | `1` |
| `colorCode` | `enum` | `"green"` / `"yellow"` / `"orange"` |
