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

## PeterParkingApp.swift

The entry point for the app. Sets `ContentView` as the root view in the app entry: `WindowGroup`

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
| `query`        | `UserQuery`       | Per-search inputs (destination, location, time).                       |
| `preferences`  | `UserPreferences` | Stored personal model (budget range, stay duration).                   |

### UserPreferences.swift

Implements the **personal model** (stored user preferences). The proposal’s “personal framework” has three main aspects: (1) **price sensitivity** (thrifty vs convenience-driven), (2) **distance acceptance** (exploration range, e.g. 200 m–800 m), and (3) **habitual parking length** (`typicalStayPreference`) for filtering out spots with insufficient time limits. These preferences are applied across searches; budget for a specific search is expressed in `UserQuery.budgetRangePreference`, not here.

| Parameter                   | Type                    | Notes                                                                 |
| --------------------------- | ----------------------- | --------------------------------------------------------------------- |
| `budgetRange`               | `BudgetRangePreference` | Budget category (low / medium / high); influences ranking cost weight. |
| `stayDuration`              | `StayTimePreference`   | Stay duration category (short / medium / long); influences time-limit scoring. |

### SessionManager.swift

Singleton **session manager** that persists user preferences in `UserDefaults`. On launch, stored preferences are loaded and used to prefill the search form pickers; when the user changes budget or stay in the form, `onChange` handlers update the session and log the change. `ParkingViewModel` uses `SessionManager.userPreferences` when performing a search so the API receives the stored budget and stay values for ranking.

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

## Services

### APIClient.swift

`APIClient.swift` is responsible for handling communication between the iOS app and the FastAPI backend service. It defines a shared singleton client that formats requests, encodes user query and preference data into JSON, sends asynchronous network requests, and decodes the backend’s ranked parking results into app-usable models. For development and testing, the client currently operates in a simulated mode using `useMockMode`, which bypasses real network calls and instead returns predefined mock data. This allows the app to demonstrate full API client behavior and UI data flow even when the backend is not yet connected or available.

## Utils

### Theme.swift

`Theme.swift` consists of the defined static variable definitions for the app's theme. These variables can be changed to give the app a different look. For example, `primary` represents the primary color of the app.

## ViewModels

The ViewModels layer holds the app’s presentation logic and state. It drives the UI by exposing observable state and actions that views bind to and invoke.

### ParkingViewModel.swift

Single source of truth for the main search flow. Defines **ParkingUIState** (`.initial`, `.loading`, `.results(RankedResults)`, `.noResults`, `.error(String)`) and publishes it via `@Published var uiState`. Also publishes form inputs (`targetLocation`, `budgetRangePreference`, `stayTimePreference`), auto-captured **currentLocation** (from `CLLocationManager`) and **currentTime**, and exposes **mapCenter** (current location or fallback `laCenter` for Downtown LA) and **rankedResults** (the `RankedResults` when in `.results`). Integrates with **SessionManager** to persist user preferences; picker values are initialized from stored preferences on launch. **searchParking()** builds a `UserQuery` from form inputs and uses `SessionManager.userPreferences`, sets `uiState = .loading`, calls `APIClient.searchParking` in a `Task`, then sets `uiState` to `.results`, `.noResults`, or `.error` depending on the response. **updateBudgetPreference()** and **updateStayDurationPreference()** save picker changes to the session. **retry()** re-runs the search; **resetToInitial()** clears back to `.initial`. Uses `@MainActor` so all updates happen on the main thread for SwiftUI. Injected with `APIClient.shared` and `SessionManager.shared` by default so dependencies can be swapped for testing.

## Views

The Views layer implements the UI described in the proposal: search form, map, and ranked results panel (Uber-style layout). All main views observe `ParkingViewModel` and reflect its state (initial, loading, results, no results, error).

### ContentView.swift

Root container for the main screen. Composes the layout in a single vertical stack: **SearchFormView** at the top, a **Divider**, **MapView** (fixed height 280 pt), another **Divider**, and **ResultsListView** filling the remaining space. Holds a single `@StateObject` `ParkingViewModel` and passes it to child views. Disables the search form while `uiState == .loading`. Uses `Color(.systemGroupedBackground)` for the background.

### SearchFormView.swift

Search input area. Provides a **TextField** for destination (e.g. "Pantages Theatre") with a mappin icon, **Pickers** for budget range and stay time (bound to `viewModel.budgetRangePreference` and `viewModel.stayTimePreference`), and a **"Find Parking"** button that calls `viewModel.searchParking()`. Pickers are prefilled from stored session preferences on launch; `.onChange` handlers persist preference changes to `SessionManager`. On loading, the button shows a `ProgressView` instead of text. The button is disabled when the destination is empty or when already loading. Includes `BudgetRangePreference` and `StayTimePreference` display-name extensions for picker labels (e.g. "Low ($0–$10)", "Short (≤1 hr)").

### MapView.swift

SwiftUI **Map** (MapKit) centered on a fixed LA region (Downtown LA: lat 34.0522, lng -118.2437; span 0.03). When `viewModel.rankedResults` has spots, it renders an **Annotation** for each spot at `spot.coordinate`, using **MeterPinView** as the annotation content. Uses standard map style and allows hit testing. Does not show pins in initial, loading, no-results, or error states.

### ResultsListView.swift

Bottom panel that switches on `viewModel.uiState`. **Initial:** placeholder with map icon and "Enter a destination and tap Find Parking". **Loading:** `ProgressView` and "Searching for spots...". **Results:** scrollable `LazyVStack` of **SpotCardView** for each spot. **No results:** message "No spots found", suggestion to expand radius or adjust preferences, and a Retry button. **Error:** warning icon, "Something went wrong", the error message, and a Retry button. Retry calls `viewModel.retry()`.

### SpotCardView.swift

Single **score card** for one `ScoredSpot`. Displays meter ID and rank in a header row, the meter address, a row of labels (walk time, $/hr rate, time limit), and estimated total cost. Card has a colored border from `spot.colorCode.color` (green / yellow / orange), rounded corners, shadow, and uses `Theme.cardBackground`. Matches the proposal’s card content (spaceid, address, walk time, rate, timelimit, estimated cost, rank).

### MeterPinView.swift

Small view used as map **annotation** content for each spot. Shows a filled mappin SF Symbol tinted with `spot.colorCode.color` and the spot’s `spaceid` below in caption text. Used inside **MapView**’s `Annotation(spot.spaceid, coordinate: spot.coordinate, ...)` so each ranked spot appears as a labeled pin on the map.

### PreferencesView.swift

Placeholder for the **personal model / preferences** screen. Currently only shows the text "Preferences". Users edit preferences via the search form pickers; PreferencesView remains a placeholder for future expansion.

## Troubleshooting

### Backend Connection Issues

If the app shows a connection error, loading spinner that never completes, or "no results" when testing with real backend (`useMockMode = false`), the backend server has likely stopped running.

**Common causes:**
- Closed the terminal window where the server was running
- Computer went to sleep or was restarted
- Accidentally pressed Ctrl+C in the server terminal

**To check if the backend is running:**
```bash
ps aux | grep uvicorn
```

If you only see the `grep` command itself (no `uvicorn` process), the server is not running.

**To restart the backend:**
```bash
cd "/Users/dsetty/College/Classes/CS 125/cs-125"
/Users/dsetty/Library/Python/3.10/bin/uvicorn src.api:app --reload --host 0.0.0.0 --port 8000
```

You should see output like:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [####]
INFO:     Application startup complete.
```

**Important:** Keep the terminal window open while testing the app. Closing it will stop the server. If you need to run other commands, open a separate terminal tab (⌘T) instead of closing the server terminal.

## Running Frontend Example
Assuming that you have a Macbook Pro and have XCode installed, simply click open the `cs-125.xcodeproj` file in XCode. 

Once the project is successfully opened, there should be a play button that you can click to boot up the app. 

![User Interface Screenshot](frontend_example.png)

---
> AI Acknowledgement: AI tools were used during development for implementation support.
