import Foundation
import CoreLocation

struct UserQuery: Codable {
    let destination: String                         // user's desired destination
    let durationMinutes: Int                        // user's intended parking stay duration
    let currentLocation: CLLocationCoordinate2D     // user's current coordinate location
    let currentTime: Date                           // time as of this query's processing
}