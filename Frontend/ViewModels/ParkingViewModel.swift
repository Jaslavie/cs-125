import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

// MARK: - Journey Summary

/*
 * Snapshot produced when the user ends an active parking journey.
 * Captures the full selection history, the final chosen spot, and the total elapsed time.
 *
 * Attributes:
 * - chosenSpots: Every spot the user deliberately selected during the journey, in chronological order.
 * - finalSpot: The last spot in chosenSpots; the spot the user was navigating to when the journey ended.
 * - durationMinutes: Total elapsed time from the moment results were first shown to the EndJourney tap.
 */
struct JourneySummary: Equatable {
    let chosenSpots: [ScoredSpot]
    let finalSpot: ScoredSpot?
    let durationMinutes: Int
}

// MARK: - Parking UI State

/*
 * UI states for the results panel and map: initial (empty), loading (progress), results (ranked list of spots),
 * no results (suggestion to expand radius), error (alert with retry), or journeyComplete (summary screen).
 *
 * Attributes:
 * - initial: Empty state before any search.
 * - loading: Search in progress; form disabled, progress shown.
 * - results(RankedResults): Ranked set of spots; map shows pins, panel shows cards.
 * - noResults: No spots found; suggest expanding radius.
 * - error(String): Failure with message; alert with retry.
 * - journeyComplete(JourneySummary): Journey has ended; results panel shows journey summary.
*/
enum ParkingUIState: Equatable {
    case initial
    case loading
    case results(RankedResults)
    case noResults
    case error(String)
    case journeyComplete(JourneySummary)
}

// MARK: - Location Delegate

/*
 * Private CLLocationManagerDelegate bridge that forwards location callbacks to ParkingViewModel
 * via closures. Required because CLLocationManagerDelegate is an Objective-C protocol and cannot
 * be adopted directly by an @MainActor-isolated class.
 *
 * Attributes:
 * - onLocationUpdate: Closure invoked with the most recent CLLocation each time the device reports a new position.
 * - onAuthorizationChange: Closure invoked when the app's location authorization status changes.
 */
private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    /*
     * Forwards the most recent location fix to the view model.
     *
     * Parameters:
     * - manager: The location manager that generated the update.
     * - locations: Array of new location objects; the last entry is the most recent fix.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate?(location)
    }

    /*
     * Restarts location updates when authorization is granted after the initial request.
     *
     * Parameters:
     * - manager: The location manager whose authorization status changed.
     */
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChange?(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently ignore location errors; view model falls back to laCenter.
    }
}

// MARK: - Parking View Model

/*
 * Single source of truth for the main search flow. The user enters intended destination and stay duration;
 * currentLocation and currentTime are auto-captured. The personal model (price sensitivity, distance acceptance,
 * typical stay) is combined with the query and sent to the recommendation engine, which returns a ranked list of optimal parking spots.
 *
 * Attributes:
 * - uiState: Drives the results panel and map (initial, loading, results, no results, error, or journeyComplete).
 * - targetLocation: Free-text destination; user-entered, geocoded by backend.
 * - budgetRangePreference: Stored budget category shown in picker; synced with SessionManager (low/medium/high).
 * - stayTimePreference: Stored stay duration category shown in picker; synced with SessionManager (short/medium/long).
 * - currentLocation: From device GPS; used for ranking, route calculation, and map center when available.
 * - currentTime: Auto-captured at query time so recommendations use the moment of the search.
 * - selectedSpotID: The spaceid of the card the user has tapped; drives route rendering and card highlight.
 * - liveOccupancy: Latest polled occupancy state for each ranked spaceid; keyed by spaceid string.
 * - selectedRoute: Computed MKRoute from user location to the selected spot; rendered as a polyline on the map.
 * - showSpotOccupiedAlert: True when the selected spot transitions from VACANT to OCCUPIED; triggers the alert.
 * - journeyHistory: Ordered list of every spot the user has selected since the last search.
 * - hasAnyVacantRankedSpots: True if at least one non-selected ranked spot is currently VACANT.
 * - mapCenter: User location when available, otherwise LA center.
 * - rankedResults: The ranked list when in .results state; used by MapView and ResultsListView.
 * - laCenter: Fallback when GPS is unavailable; Downtown LA center.
 */
@MainActor
final class ParkingViewModel: ObservableObject {
    // MARK: - Published State
    @Published var uiState: ParkingUIState = .initial
    @Published var targetLocation: String = ""
    @Published var budgetRangePreference: BudgetRangePreference = .medium
    @Published var stayTimePreference: StayTimePreference = .medium
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentTime: Date = Date()
    @Published var selectedSpotID: String? = nil  // spaceid of the currently selected card
    @Published var liveOccupancy: [String: String] = [:]  // spaceid → "VACANT" / "OCCUPIED" / "UNKNOWN"
    @Published var selectedRoute: MKRoute? = nil  // route from user location to selected spot
    @Published var showSpotOccupiedAlert: Bool = false  // triggers the occupied-spot alert
    @Published var journeyHistory: [ScoredSpot] = []  // all spots selected in chronological order

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let sessionManager: SessionManager  // Persists and provides stored user preferences (budget, stay duration)
    private let locationManager = CLLocationManager()
    private let locationDelegate = LocationDelegate()  // Bridges CLLocationManagerDelegate to the @MainActor view model

    // MARK: - Private State
    private var occupancyPollingTask: Task<Void, Never>?  // background task running the occupancy poll loop
    private var journeyStartTime: Date? = nil  // timestamp when results first appeared; used to compute journey duration

    static let laCenter = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)

    // MARK: - Computed Properties

    /*
     * Computed property that returns the user's location when available, otherwise LA center.
     */
    var mapCenter: CLLocationCoordinate2D {
        currentLocation ?? Self.laCenter
    }

    /*
     * Computed property that returns true if the UI state is .results, otherwise false.
     */
    var hasResults: Bool {
        if case .results = uiState { return true }
        return false
    }

    /*
     * Computed property that returns the ranked results when the UI state is .results, otherwise nil.
     */
    var rankedResults: RankedResults? {
        if case .results(let results) = uiState { return results }
        return nil
    }

    /*
     * Computed property that returns true if at least one non-selected ranked spot has a live
     * occupancy value other than "OCCUPIED". Used to decide which buttons appear in the occupied alert.
     */
    var hasAnyVacantRankedSpots: Bool {
        guard let spots = rankedResults?.spots else { return false }
        return spots.contains { spot in
            guard spot.spaceid != selectedSpotID else { return false }
            let occ = liveOccupancy[spot.spaceid] ?? spot.occupancy
            return occ != "OCCUPIED"
        }
    }

    // MARK: - Init
    /*
     * Initializes the view model with the API client and SessionManager, and sets up the location manager.
     * Picker values (budgetRangePreference, stayTimePreference) are initialized from stored session preferences.
     *
     * Parameters:
     * - apiClient: API client for backend requests (default: shared).
     * - sessionManager: Session manager for stored preferences (default: shared).
     */
    init(apiClient: APIClient = .shared, sessionManager: SessionManager = .shared) {
        self.apiClient = apiClient
        self.sessionManager = sessionManager
        setupLocationManager()
        // Initialize pickers from stored preferences so UI shows last-used values
        self.budgetRangePreference = sessionManager.userPreferences.budgetRange
        self.stayTimePreference = sessionManager.userPreferences.stayDuration
    }

    /*
     * Configures the CLLocationManager with a delegate and starts receiving GPS updates so that
     * currentLocation is kept current throughout the session. Authorization is requested on first call.
     */
    private func setupLocationManager() {
        locationManager.delegate = locationDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        locationDelegate.onLocationUpdate = { [weak self] location in
            Task { @MainActor [weak self] in
                self?.currentLocation = location.coordinate
            }
        }

        locationDelegate.onAuthorizationChange = { [weak self] status in
            Task { @MainActor [weak self] in
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    self?.locationManager.startUpdatingLocation()
                }
            }
        }
    }

    // MARK: - Actions
    /*
     * Builds UserQuery (per-query inputs) and UserPreferences (personal model), then calls the API
     * to gather spots within the user's walking radius and sort them into a ranked list.
     * Resets all journey state and starts occupancy polling on success.
     */
    func searchParking() {
        guard !targetLocation.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        stopOccupancyPolling()
        uiState = .loading
        currentTime = Date()
        selectedSpotID = nil
        selectedRoute = nil
        liveOccupancy = [:]
        journeyHistory = []
        journeyStartTime = nil
        apiClient.resetMockOccupancyOverrides()  // Clear debug-panel overrides so each search starts clean.

        let coordinate = currentLocation.map { Coordinate($0) } ?? Coordinate(Self.laCenter)
        let query = UserQuery(
            targetLocation: targetLocation.trimmingCharacters(in: .whitespaces),
            currentLocation: coordinate,
            currentTime: currentTime,
            budgetRangePreference: budgetRangePreference,
            stayTimePreference: stayTimePreference
        )  // Per-query inputs: targetLocation, currentLocation, currentTime, budgetRangePreference, stayTimePreference.

        // Use stored preferences from session; sent to backend for ranking (budget and stay duration)
        let preferences = sessionManager.userPreferences

        Task {
            do {
                let results = try await apiClient.searchParking(query: query, preferences: preferences)
                if results.spots.isEmpty {
                    uiState = .noResults
                } else {
                    uiState = .results(results)
                    journeyStartTime = Date()
                    startOccupancyPolling()
                }
            } catch {
                uiState = .error(error.localizedDescription)
            }
        }
    }

    /*
     * Re-runs search after no results or error; used by the error-state retry option.
     */
    func retry() {
        searchParking()
    }

    /*
     * Resets UI to initial state (empty map, form visible). Stops all background processes.
     */
    func resetToInitial() {
        stopOccupancyPolling()
        selectedSpotID = nil
        selectedRoute = nil
        liveOccupancy = [:]
        journeyHistory = []
        journeyStartTime = nil
        uiState = .initial
    }

    // MARK: - Spot Selection

    /*
     * Marks the given spot as the active selection, appends it to the journey history,
     * and kicks off a fresh route calculation to that spot.
     *
     * Parameters:
     * - spot: The ScoredSpot the user tapped.
     */
    func selectSpot(_ spot: ScoredSpot) {
        selectedSpotID = spot.spaceid
        journeyHistory.append(spot)
        calculateRoute(to: spot)
    }

    /*
     * Clears the current spot selection and removes the route polyline from the map.
     */
    func deselectSpot() {
        selectedSpotID = nil
        selectedRoute = nil
    }

    /*
     * Selects the highest-ranked (lowest rank number) spot that is currently VACANT and is not
     * the already-selected spot. Called by the "Select Next Best" alert action.
     */
    func selectNextBestVacantSpot() {
        guard let spots = rankedResults?.spots else { return }
        if let nextBest = spots.first(where: { spot in
            guard spot.spaceid != selectedSpotID else { return false }
            let occ = liveOccupancy[spot.spaceid] ?? spot.occupancy
            return occ != "OCCUPIED"
        }) {
            selectSpot(nextBest)
        }
    }

    // MARK: - Occupancy Polling

    /*
     * Starts a background Task that polls the occupancy endpoint every 7 seconds.
     * Any previously running polling task is cancelled before starting a new one.
     */
    func startOccupancyPolling() {
        stopOccupancyPolling()
        occupancyPollingTask = Task {
            while !Task.isCancelled {
                await refreshOccupancy()
                try? await Task.sleep(nanoseconds: 7_000_000_000)
            }
        }
    }

    /*
     * Cancels the active occupancy polling task, if any.
     */
    func stopOccupancyPolling() {
        occupancyPollingTask?.cancel()
        occupancyPollingTask = nil
    }

    /*
     * Forces an immediate occupancy refresh outside the normal 7-second polling cycle.
     * Used by the mock debug panel so override changes take effect the moment a picker is moved.
     */
    func triggerMockOccupancyRefresh() {
        Task { await refreshOccupancy() }
    }

    /*
     * Fetches the latest occupancy state for all currently ranked spots, detects a VACANT→OCCUPIED
     * transition on the selected spot (which triggers the occupied alert), and updates liveOccupancy.
     */
    private func refreshOccupancy() async {
        guard let spots = rankedResults?.spots, !spots.isEmpty else { return }
        let spaceids = spots.map { $0.spaceid }
        do {
            let newOccupancy = try await apiClient.fetchOccupancy(spaceids: spaceids)

            // Log the full occupancy snapshot to the Xcode console on every poll.
            let timestamp = Date().formatted(.iso8601)
            print("\n[OCCUPANCY POLL] \(timestamp)")
            print("  Queried : \(spaceids.count) space IDs")
            print("  Returned: \(newOccupancy.count) with sensor data (\(spaceids.count - newOccupancy.count) have no sensor coverage)")
            for sid in spaceids {
                let status = newOccupancy[sid] ?? "NO SENSOR DATA"
                let marker = sid == selectedSpotID ? " ◀ selected" : ""
                print("  \(sid.padding(toLength: 12, withPad: " ", startingAt: 0)) → \(status)\(marker)")
            }

            // Detect VACANT → OCCUPIED transition on the currently selected spot.
            if let selectedID = selectedSpotID,
               let newStatus = newOccupancy[selectedID],
               newStatus == "OCCUPIED",
               (liveOccupancy[selectedID] ?? "VACANT") != "OCCUPIED" {
                print("  ⚠️  Selected spot \(selectedID) transitioned VACANT → OCCUPIED")
                showSpotOccupiedAlert = true
            }
            liveOccupancy = newOccupancy
        } catch {
            print("[OCCUPANCY POLL] ⚠️  Poll failed: \(error.localizedDescription)")
            // Stale occupancy values remain until the next successful poll.
        }
    }

    // MARK: - Route Calculation

    /*
     * Calculates a driving route from the user's current location (or LA center as fallback) to the
     * given spot using MKDirections, then stores the first result in selectedRoute for map rendering.
     *
     * Parameters:
     * - spot: The destination ScoredSpot whose coordinate is used as the route endpoint.
     */
    private func calculateRoute(to spot: ScoredSpot) {
        let sourceCoord = currentLocation ?? Self.laCenter
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoord)
        let source = MKMapItem(placemark: sourcePlacemark)

        let destinationPlacemark = MKPlacemark(coordinate: spot.coordinate)
        let destination = MKMapItem(placemark: destinationPlacemark)

        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile

        Task {
            let directions = MKDirections(request: request)
            if let response = try? await directions.calculate(),
               let firstRoute = response.routes.first {
                selectedRoute = firstRoute
            }
        }
    }

    // MARK: - End Journey

    /*
     * Ends the active journey: stops occupancy polling, captures a JourneySummary with the full
     * selection history and elapsed time, clears navigation state, and transitions to .journeyComplete.
     */
    func endJourney() {
        stopOccupancyPolling()
        let elapsed = journeyStartTime.map { Int(Date().timeIntervalSince($0) / 60) } ?? 0
        let summary = JourneySummary(
            chosenSpots: journeyHistory,
            finalSpot: journeyHistory.last,
            durationMinutes: elapsed
        )
        selectedSpotID = nil
        selectedRoute = nil
        uiState = .journeyComplete(summary)
    }

    // MARK: - Preference Updates (persist to session)

    /*
     * Updates the stored budget preference when the user changes the budget picker.
     * Persists to SessionManager (UserDefaults) and triggers debug logging.
     *
     * Parameters:
     * - newValue: The new budget range preference selected by the user.
     */
    func updateBudgetPreference(_ newValue: BudgetRangePreference) {
        sessionManager.updateBudgetRange(newValue)
        budgetRangePreference = newValue  // Keep picker in sync
    }

    /*
     * Updates the stored stay duration preference when the user changes the stay picker.
     * Persists to SessionManager (UserDefaults) and triggers debug logging.
     *
     * Parameters:
     * - newValue: The new stay duration preference selected by the user.
     */
    func updateStayDurationPreference(_ newValue: StayTimePreference) {
        sessionManager.updateStayDuration(newValue)
        stayTimePreference = newValue  // Keep picker in sync
    }
}
