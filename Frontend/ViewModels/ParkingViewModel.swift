import Foundation
import Combine
import CoreLocation
import SwiftUI

enum ParkingUIState: Equatable {
    case initial
    case loading
    case results(RankedResults)
    case noResults
    case error(String)
}

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
    
    // LA default center (Downtown LA)
    static let laCenter = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
    
    var mapCenter: CLLocationCoordinate2D {
        currentLocation ?? Self.laCenter
    }
    
    var hasResults: Bool {
        if case .results = uiState { return true }
        return false
    }
    
    var rankedResults: RankedResults? {
        if case .results(let results) = uiState { return results }
        return nil
    }
    
    // MARK: - Init
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        if let loc = locationManager.location {
            currentLocation = loc.coordinate
        }
    }
    
    // MARK: - Actions
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
        )
        
        let preferences = UserPreferences(
            priceSensitivity: .thrifty,
            distanceAcceptanceMeters: 400,
            typicalStayPreference: stayTimePreference
        )
        
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
    
    func retry() {
        searchParking()
    }
    
    func resetToInitial() {
        uiState = .initial
    }
}
