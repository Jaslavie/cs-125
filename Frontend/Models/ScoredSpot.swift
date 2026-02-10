import Foundation
import CoreLocation
import SwiftUI

// MARK: - Score card / ranked spot (single result)
// One item in the ranked list shown to the user. Proposal: "A Ranked List of Score Cards" with
// spaceid, meterAddress, walkTime, rate, estimatedTotalCost, timelimit, rank. Cards are
// color-coded (green = highly recommended, yellow = good, orange = acceptable).

// MARK: - Color Code
// Proposal: "Cards are color-coded, with green being highly recommended, yellow being good, orange being acceptable."
enum ColorCode: String, Codable {
    case green  // Highly recommended
    case yellow // Good
    case orange // Acceptable / bare minimum
    
    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        }
    }
}

struct ScoredSpot: Codable, Identifiable, Equatable {
    /// Meter identifier (e.g. "HO108", "DT472"); from LADOT data.
    let spaceid: String
    /// Street address of the meter (e.g. "6233 Hollywood Blvd").
    let meterAddress: String
    let latitude: Double
    let longitude: Double
    /// Walk time to destination in minutes (derived from distance; ~80 m/min walking speed).
    let walkTime: Int
    /// Hourly rate in $/hr.
    let rate: Double
    /// Estimated total cost for the user's stay (rate × duration).
    let estimatedTotalCost: Double
    /// Max allowed parking duration in minutes (from meter policy).
    let timelimit: Int
    /// Position in the ranked list (1 = best match).
    let rank: Int
    /// Card color for UI: green / yellow / orange by recommendation strength.
    let colorCode: ColorCode
    
    /// Optional backend scoring components; used for display or debugging if provided.
    let priceScore: Double?
    let walkTimeScore: Double?
    let totalScore: Double?
    
    init(spaceid: String, meterAddress: String, latitude: Double, longitude: Double,
         walkTime: Int, rate: Double, estimatedTotalCost: Double, timelimit: Int,
         rank: Int, colorCode: ColorCode,
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
        self.priceScore = priceScore
        self.walkTimeScore = walkTimeScore
        self.totalScore = totalScore
    }
    
    var id: String { spaceid }
    /// For placing a pin on the map (MapView).
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}
