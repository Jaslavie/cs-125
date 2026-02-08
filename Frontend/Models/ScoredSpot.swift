import Foundation
import CoreLocation

enum ColorCode: String, Codable {
    case green  // associated with highly recommended spot
    case yellow // associated with good parking spot
    case orange // associated with acceptable, bare-minimum, parking spot
    
    var color: Color {
        switch self {
            case .green: return .green
            case .yellow: return .yellow
            case .orange: return .orange
        }
    }
}

struct ScoredSpot: Codable, Identifiable {
    let spotId: String              // parking spot id
    let address: String             // address where parking spot at
    let latitude: Double            // parking spot latitude
    let longitude: Double           // parking spot longitude
    let ratePerHour: Double         // hourly rate for this parking spot
    let walkTimeMinutes: Int        // the walking time to desired destination in minutes
    let estimatedTotalCost: Double  // estimated total cost of parking given rate and duration
    let priceScore: Double          // the score of this parking spot's price
    let walkTimeScore: Double       // the score of this parking spot's walking time
    let totalScore: Double          // the total score for this parking spot
    let rank: Int                   // the rank of this parking spot relative to all the other scored spots
    let colorCode: ColorCode        // color associated to this parking spot based on its relative quality
    
    var id: String { spotId }
    
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}