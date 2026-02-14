import Foundation
import CoreLocation

// MARK: - Coordinate
// Codable wrapper for `CLLocationCoordinate2D` so it can be serialized in `UserQuery` (e.g. `currentLocation`)
// for JSON request/response. Proposal: currentLocation is `{ lat: float, lng: float }`; this struct matches that shape.
struct Coordinate: Codable {
    let lat: Double
    let lng: Double
    /// Use when passing to MapKit or other APIs that expect `CLLocationCoordinate2D`.
    var clLocation: CLLocationCoordinate2D { .init(latitude: lat, longitude: lng) }
    
    init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
    
    init(_ coordinate: CLLocationCoordinate2D) {
        self.lat = coordinate.latitude
        self.lng = coordinate.longitude
    }
}
