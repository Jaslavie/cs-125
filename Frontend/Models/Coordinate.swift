import Foundation
import CoreLocation

// MARK: - Coordinate

/* Codable wrapper for `CLLocationCoordinate2D` to enable JSON serialization in API requests and responses.
 * `CLLocationCoordinate2D` is not natively Codable, so this struct bridges the gap between MapKit and JSON encoding.
 * Used in `UserQuery` for encoding the user's current location as `{ lat: float, lng: float }`.
 *
 * Attributes:
 * - lat: Latitude coordinate in degrees.
 * - lng: Longitude coordinate in degrees.
 * - clLocation: Computed property; converts back to `CLLocationCoordinate2D` for use with MapKit and other CoreLocation APIs.
 */
struct Coordinate: Codable {
    let lat: Double  // Latitude coordinate in degrees
    let lng: Double  // Longitude coordinate in degrees
    
    /*
     * Computed property that converts this Coordinate to `CLLocationCoordinate2D`.
     * Use when passing to MapKit or other APIs that expect `CLLocationCoordinate2D`.
     */
    var clLocation: CLLocationCoordinate2D { .init(latitude: lat, longitude: lng) }
    
    /*
     * Initialize a Coordinate with explicit latitude and longitude values.
     *
     * Parameters:
     * - lat: Latitude coordinate in degrees.
     * - lng: Longitude coordinate in degrees.
     */
    init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
    
    /*
     * Initialize a Coordinate from a `CLLocationCoordinate2D`.
     * Convenience initializer for converting device location or map coordinates to Codable format.
     *
     * Parameters:
     * - coordinate: A `CLLocationCoordinate2D` instance (e.g., from device GPS or MapKit).
     */
    init(_ coordinate: CLLocationCoordinate2D) {
        self.lat = coordinate.latitude
        self.lng = coordinate.longitude
    }
}
