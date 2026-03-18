import Foundation
import CoreLocation
import SwiftUI

// MARK: - Color Code

/* Cards are color-coded based on recommendation strength to provide visual feedback on match quality.
 * Maps rank thresholds to UI colors for visual recommendation strength.
 *
 * Attributes:
 * - green: Highly recommended option (typically rank 1-3).
 * - yellow: Good option (typically rank 4-7).
 * - orange: Acceptable or bare minimum option (typically rank 8+).
 * - color: Computed property; returns SwiftUI Color for card border styling.
 */
enum ColorCode: String, Codable {
    case green   // Highly recommended
    case yellow  // Good option
    case orange  // Acceptable / bare minimum
    
    /*
     * Computed property that converts ColorCode to SwiftUI Color.
     * Used for card border styling in SpotCardView.
     *
     * Returns: SwiftUI Color matching the color code.
     */
    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        }
    }
}

// MARK: - Score card / ranked spot (single result)

/* One ranked parking spot in the ranked list shown to the user, displayed as a score card with 
 * information related to the ranked parking spot. Each score card contains ranked parking spot 
 * information like the meter identifier, meter address, walk time, hourly rate, estimated total cost, 
 * time limit, and rank. Cards are color-coded (green = highly recommended, yellow = good, orange = acceptable).
 * Also, latitude and longitude information are included for map pin display purposes, where those coordinates are
 * converted to `CLLocationCoordinate2D` for MapView pins. Optional backend score fields like price score, walk time 
 * score, and total score are included when provided.
 *
 * Attributes:
 * - spaceid: Meter identifier (e.g. "HO108", "DT472") from LADOT data.
 * - meterAddress: Street address of the meter (e.g. "6233 Hollywood Blvd").
 * - latitude: Latitude coordinate for map pin placement.
 * - longitude: Longitude coordinate for map pin placement.
 * - walkTime: Walk time to destination in minutes (derived from distance; assumes ~80 m/min walking speed).
 * - rate: Hourly rate in dollars per hour.
 * - estimatedTotalCost: Estimated total cost for the user's stay (rate × duration).
 * - timelimit: Maximum allowed parking duration in minutes from meter policy.
 * - rank: Position in the ranked list (1 = best match).
 * - colorCode: Card color for UI styling; green, yellow, or orange by recommendation strength.
 * - occupancy: Real-time occupancy status (VACANT / OCCUPIED / UNKNOWN).
 * - priceScore: Optional backend scoring component for price; used for display or debugging if provided.
 * - walkTimeScore: Optional backend scoring component for walk time; used for display or debugging if provided.
 * - totalScore: Optional backend total scoring component; used for display or debugging if provided.
 * - id: Computed property; equals spaceid (for `Identifiable` protocol).
 * - coordinate: Computed property; converts latitude/longitude to `CLLocationCoordinate2D` for MapView pins.
 */
struct ScoredSpot: Codable, Identifiable, Equatable {
    let spaceid: String  // Meter identifier (e.g. "HO108", "DT472") from LADOT data
    let meterAddress: String  // Street address of the meter (e.g. "6233 Hollywood Blvd")
    let latitude: Double  // Latitude coordinate for map pin placement
    let longitude: Double  // Longitude coordinate for map pin placement
    let walkTime: Int  // Walk time to destination in minutes (assumes ~80 m/min walking speed)
    let rate: Double  // Hourly rate in dollars per hour
    let estimatedTotalCost: Double  // Estimated total cost for user's stay (rate × duration)
    let timelimit: Int  // Maximum allowed parking duration in minutes from meter policy
    let rank: Int  // Position in ranked list (1 = best match)
    let colorCode: ColorCode  // Card color for UI; green, yellow, or orange by recommendation strength
    let occupancy: String  // Occupancy status from backend (VACANT / OCCUPIED / UNKNOWN)
    
    let priceScore: Double?  // Optional backend scoring component for price
    let walkTimeScore: Double?  // Optional backend scoring component for walk time
    let totalScore: Double?  // Optional backend total scoring component
    
    /*
     * CodingKeys for mapping backend JSON field names (snake_case) to Swift property names (camelCase).
     * Backend returns: address, walk_time_minutes, rate_per_hour, estimated_total_cost, time_limit_minutes, color_code, etc.
     * Swift uses: meterAddress, walkTime, rate, estimatedTotalCost, timelimit, colorCode, etc.
     */
    enum CodingKeys: String, CodingKey {
        case spaceid
        case meterAddress = "address"
        case latitude
        case longitude
        case walkTime = "walk_time_minutes"
        case rate = "rate_per_hour"
        case estimatedTotalCost = "estimated_total_cost"
        case timelimit = "time_limit_minutes"
        case rank
        case colorCode = "color_code"
        case occupancy
        case priceScore = "price_score"
        case walkTimeScore = "walk_time_score"
        case totalScore = "total_score"
    }
    
    /*
     * Initializer for creating a ScoredSpot instance programmatically (e.g., for mock data or testing).
     *
     * Parameters:
     * - spaceid: Meter identifier.
     * - meterAddress: Street address of the meter.
     * - latitude: Latitude coordinate.
     * - longitude: Longitude coordinate.
     * - walkTime: Walk time to destination in minutes.
     * - rate: Hourly rate in dollars per hour.
     * - estimatedTotalCost: Estimated total cost for the stay.
     * - timelimit: Maximum allowed parking duration in minutes.
     * - rank: Position in the ranked list.
     * - colorCode: Card color code.
     * - occupancy: Occupancy status (default: "UNKNOWN").
     * - priceScore: Optional price score component.
     * - walkTimeScore: Optional walk time score component.
     * - totalScore: Optional total score component.
     */
    init(spaceid: String, meterAddress: String, latitude: Double, longitude: Double,
         walkTime: Int, rate: Double, estimatedTotalCost: Double, timelimit: Int,
         rank: Int, colorCode: ColorCode, occupancy: String = "UNKNOWN",
         priceScore: Double? = nil, walkTimeScore: Double? = nil, totalScore: Double? = nil) {
        self.spaceid = spaceid
        self.meterAddress = meterAddress
        self.latitude = latitude
        self.longitude = longitude
        self.walkTime = walkTime
        self.rate = rate
        self.estimatedTotalCost = estimatedTotalCost
        self.timelimit = timelimit
        self.rank = rank
        self.colorCode = colorCode
        self.occupancy = occupancy
        self.priceScore = priceScore
        self.walkTimeScore = walkTimeScore
        self.totalScore = totalScore
    }
    
    /*
     * Computed property for `Identifiable` protocol.
     * Uses spaceid as the unique identifier for SwiftUI list iteration.
     *
     * Returns: The spaceid string.
     */
    var id: String { spaceid }
    
    /*
     * Computed property that converts latitude/longitude to `CLLocationCoordinate2D`.
     * Used for placing a pin on the map in MapView.
     *
     * Returns: CLLocationCoordinate2D for MapKit annotation placement.
     */
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}
