import Foundation

// MARK: - Personal model (stored user preferences)
// Proposal: "The personal framework tracks three principal user aspects that shape the ranking process."
// These preferences are stored (e.g. after onboarding) and applied across searches.

// MARK: - Price Sensitivity
// Price awareness: "thrifty" users favor cheaper options even if farther; "convenience-driven" users favor proximity over cost.
enum PriceSensitivity: String, Codable {
    case thrifty      // Prefer lower cost; willing to walk farther.
    case convenience  // Prefer proximity; less sensitive to price.
}

struct UserPreferences: Codable {
    /// Shapes how cost vs. distance is weighted in ranking.
    var priceSensitivity: PriceSensitivity
    /// Exploration range in meters. Proposal: ~200m (immediate) to ~800m (~10 min walk).
    var distanceAcceptanceMeters: Int
    /// Default stay duration for filtering; removes spots with insufficient time limits.
    var typicalStayPreference: StayTimePreference
}
