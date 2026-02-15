import Foundation
import Combine
import CoreLocation
import SwiftUI

// MARK: - Parking UI State

/*
 * UI states for the results panel and map: initial (empty), loading (progress), results (ranked list of spots),
 * no results (suggestion to expand radius), or error (alert with retry).
 *
 * Attributes:
 * - initial: Empty state before any search.
 * - loading: Search in progress; form disabled, progress shown.
 * - results(RankedResults): Ranked set of spots; map shows pins, panel shows cards.
 * - noResults: No spots found; suggest expanding radius.
 * - error(String): Failure with message; alert with retry.
*/
enum ParkingUIState: Equatable {
    case initial
    case loading
    case results(RankedResults)
    case noResults
    case error(String)
}

// MARK: - Parking View Model

/*
 * Single source of truth for the main search flow. The user enters intended destination and stay duration;
 * currentLocation and currentTime are auto-captured. The personal model (price sensitivity, distance acceptance,
 * typical stay) is combined with the query and sent to the recommendation engine, which returns a ranked list of optimal parking spots.
 *
 * Attributes:
 * - uiState: Drives the results panel and map (initial, loading, results, no results, or error).
 * - targetLocation: Free-text destination; user-entered, geocoded by backend.
 * - budgetRangePreference: Per-query max total cost category (low/medium/high); maps to dollar ranges.
 * - stayTimePreference: Per-query planned stay category (short/medium/long); filters out inadequate time limits.
 * - currentLocation: From device GPS; used for ranking and map center when available.
 * - currentTime: Auto-captured at query time so recommendations use the moment of the search.
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

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let locationManager = CLLocationManager()

    static let laCenter = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)

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

    // MARK: - Init
    /*
     * Initializes the view model with the API client and sets up the location manager.
     */
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        setupLocationManager()
    }

    /*
     * Requests location permission and starts updates so currentLocation is set from device GPS.
     */
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        if let loc = locationManager.location {
            currentLocation = loc.coordinate
        }
    }

    // MARK: - Actions
    /*
     * Builds UserQuery (per-query inputs) and UserPreferences (personal model), then calls the API 
     * to gather spots within the user's walking radius and sort them into a ranked list.
     */
    func searchParking() {
        guard !targetLocation.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        uiState = .loading
        currentTime = Date()

        let coordinate = currentLocation.map { Coordinate($0) } ?? Coordinate(Self.laCenter)
        let query = UserQuery(
            targetLocation: targetLocation.trimmingCharacters(in: .whitespaces),
            currentLocation: coordinate,
            currentTime: currentTime,
            budgetRangePreference: budgetRangePreference,
            stayTimePreference: stayTimePreference
        )  // Per-query inputs: targetLocation, currentLocation, currentTime, budgetRangePreference, stayTimePreference.

        let preferences = UserPreferences(
            priceSensitivity: .thrifty,
            distanceAcceptanceMeters: 400,
            typicalStayPreference: stayTimePreference
        )  // Personal model: price sensitivity, distance acceptance, typical stay for filtering.

        Task {
            do {
                let results = try await apiClient.searchParking(query: query, preferences: preferences)
                if results.spots.isEmpty {
                    uiState = .noResults
                } else {
                    uiState = .results(results)
                }
            } catch {
                uiState = .error(error.localizedDescription)
            }
        }
    }

    /*
     * Re-runs search after no results or error; used by the error-state retry option.
     *
     */
    func retry() {
        searchParking()
    }

    /*
     * Resets UI to initial state (empty map, form visible).
     *
     */
    func resetToInitial() {
        uiState = .initial
    }
}
