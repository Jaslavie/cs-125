# Frontend

## Directory tree

```
Frontend/
├── Assets.xcassets/
├── Models/
│   ├── RankedResults.swift
│   ├── ScoredSpot.swift
│   ├── UserPreferences.swift
│   └── UserQuery.swift
├── PetrParkingApp.swift
├── Services/
│   └── APIClient.swift
├── Utils/
│   └── Theme.swift
├── ViewModels/
│   └── ParkingViewModel.swift
└── Views/
    ├── ContentView.swift
    ├── MapView.swift
    ├── MeterPinView.swift
    ├── PreferencesView.swift
    ├── ResultsListView.swift
    ├── SearchFormView.swift
    └── SpotCardView.swift
```

## Models

The Models layer holds the data types used for user input, API requests/responses, and the personal model. They align with the proposal’s user-query fields, personal framework, and ranked score-card output.

### Coordinate.swift

Defines a **Codable wrapper for `CLLocationCoordinate2D`**. The proposal specifies `currentLocation` as `{ lat: float, lng: float }`; `CLLocationCoordinate2D` is not `Codable`, so this struct is used in `UserQuery` (and anywhere else we need to encode/decode coordinates as JSON). It exposes `clLocation` for use with MapKit and other APIs that expect `CLLocationCoordinate2D`.

| Parameter   | Type                    | Notes                                                                 |
| ----------- | ----------------------- | --------------------------------------------------------------------- |
| `lat`       | `Double`                | Latitude.                                                             |
| `lng`       | `Double`                | Longitude.                                                            |
| `clLocation`| `CLLocationCoordinate2D`| Computed; use for MapKit and other APIs expecting `CLLocationCoordinate2D`. |

### RankedResults.swift

Represents the **response from the backend search endpoint**: a ranked list of recommended parking spots. The proposal says the system “delivers a ranked list of optimal parking spots near the user’s desired location,” typically 5–8 options. It contains the array of `ScoredSpot` items (for the results panel and map pins), the number of candidates evaluated, and the query timestamp. Conforms to `Equatable` for use in `ParkingUIState`.

| Parameter                   | Type            | Notes                                                                 |
| --------------------------- | --------------- | --------------------------------------------------------------------- |
| `spots`                     | `[ScoredSpot]`  | Ranked score cards (best match first); shown in results panel and map. |
| `totalCandidatesEvaluated`  | `Int`           | Number of candidate spots considered before filtering/ranking.        |
| `queryTimestamp`           | `Date`          | Time the query was processed (matches `UserQuery.currentTime`).       |

### ScoredSpot.swift

Models **one item in the ranked list**—a single “score card” shown to the user. The proposal’s output schema includes: `spaceid`, meter address, walk time (minutes), hourly rate, estimated total cost, time limit (minutes), and rank. This file adds `latitude`/`longitude` for map pins and `colorCode` (green / yellow / orange) for card styling per the proposal (“green = highly recommended, yellow = good, orange = acceptable”). Optional backend score fields are included when the backend provides them.

**ColorCode** (enum): `green` = highly recommended; `yellow` = good; `orange` = acceptable. Exposes `color: Color` for SwiftUI.

| Parameter             | Type        | Notes                                                                 |
| --------------------- | ----------- | --------------------------------------------------------------------- |
| `spaceid`             | `String`    | Meter identifier (e.g. "HO108", "DT472"); from LADOT data.            |
| `meterAddress`        | `String`    | Street address of the meter (e.g. "6233 Hollywood Blvd").             |
| `latitude`, `longitude` | `Double`  | For map pin placement.                                                |
| `walkTime`            | `Int`       | Walk time to destination in minutes (~80 m/min walking speed).        |
| `rate`                | `Double`    | Hourly rate ($/hr).                                                   |
| `estimatedTotalCost`  | `Double`    | Estimated total cost for the user's stay (rate × duration).           |
| `timelimit`           | `Int`       | Max allowed parking duration in minutes (from meter policy).          |
| `rank`                | `Int`       | Position in ranked list (1 = best match).                             |
| `colorCode`           | `ColorCode` | Card color: green / yellow / orange by recommendation strength.       |
| `priceScore`, `walkTimeScore`, `totalScore` | `Double?` | Optional backend scoring components; for display or debugging.  |
| `id`                  | `String`    | Computed; equals `spaceid` (for `Identifiable`).                       |
| `coordinate`          | `CLLocationCoordinate2D` | Computed; for MapView pins.                                    |

### SearchRequest.swift

Defines the **request body sent to the backend search API**. It combines the per-query inputs (`UserQuery`) with the user’s stored preferences (`UserPreferences`) so the ranking engine can produce a context-aware ranked list. Used by `APIClient.searchParking` when encoding the POST body.

| Parameter      | Type              | Notes                                                                 |
| -------------- | ----------------- | --------------------------------------------------------------------- |
| `query`        | `UserQuery`       | Per-search inputs (destination, location, time, budget, stay).        |
| `preferences`  | `UserPreferences` | Stored personal model (price sensitivity, distance, stay).            |

### UserPreferences.swift

Implements the **personal model** (stored user preferences). The proposal’s “personal framework” has three main aspects: (1) **price sensitivity** (thrifty vs convenience-driven), (2) **distance acceptance** (exploration range, e.g. 200 m–800 m), and (3) **habitual parking length** (`typicalStayPreference`) for filtering out spots with insufficient time limits. These preferences are applied across searches; budget for a specific search is expressed in `UserQuery.budgetRangePreference`, not here.

**PriceSensitivity** (enum): `thrifty` = prefer lower cost, willing to walk farther; `convenience` = prefer proximity, less sensitive to price.

| Parameter                   | Type                  | Notes                                                                 |
| --------------------------- | --------------------- | --------------------------------------------------------------------- |
| `priceSensitivity`          | `PriceSensitivity`    | Shapes how cost vs. distance is weighted in ranking.                   |
| `distanceAcceptanceMeters`  | `Int`                 | Exploration range in meters (~200 = immediate, ~800 = ~10 min walk).   |
| `typicalStayPreference`     | `StayTimePreference`  | Default stay duration for filtering; removes spots with short limits. |

### UserQuery.swift

Captures **per-search user input** for each parking request. Aligns with the proposal’s “User Need → System Response”: the user supplies an intended destination and stay duration; `currentLocation` and `currentTime` are auto-captured. Defines **BudgetRangePreference** (max total cost category: low / medium / high) and **StayTimePreference** (short / medium / long) as specified in the proposal’s category mappings. This struct is sent as part of `SearchRequest` and encoded with ISO 8601 for `currentTime` when calling the API.

**BudgetRangePreference** (enum): `low` = $0–$10; `medium` = $10–$20; `high` = $20–$50 (max total cost user is willing to pay).

**StayTimePreference** (enum): `short` = 0–60 min; `medium` = 60–120 min; `long` = 120–240 min (how long user plans to park).

| Parameter                | Type                     | Notes                                                                 |
| ------------------------ | ------------------------ | --------------------------------------------------------------------- |
| `targetLocation`         | `String`                 | Free-text destination (e.g. "Pantages Theatre"); geocoded by backend.  |
| `currentLocation`        | `Coordinate`             | User's current position from device GPS.                              |
| `currentTime`            | `Date`                    | Time at which the query is processed; auto-captured; ISO 8601 for API. |
| `budgetRangePreference`  | `BudgetRangePreference`   | Max total cost category for this search.                              |
| `stayTimePreference`     | `StayTimePreference`     | Planned parking duration category for this search.                     |
