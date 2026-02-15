import Foundation

// MARK: - Price Sensitivity

/* Price awareness level for balancing cost and convenience. Thrifty users favor cheaper options
 * even if farther away; convenience-driven users favor proximity and are less sensitive to price differences.
 * This enum influences the ranking weights between cost and distance in the recommendation algorithm.
 *
 * Attributes:
 * - thrifty: Prefer lower cost; willing to walk farther to save money.
 * - convenience: Prefer proximity; less sensitive to price differences.
 */
enum PriceSensitivity: String, Codable {
    case thrifty      // Prefer lower cost; willing to walk farther
    case convenience  // Prefer proximity; less sensitive to price
}

// MARK: - Personal model (stored user preferences)

/* The personal framework tracks three principal user aspects that shape the ranking process.
 * These preferences are stored (e.g., after onboarding) and applied across searches to provide
 * personalized parking recommendations based on the user's typical behavior and priorities.
 *
 * Attributes:
 * - priceSensitivity: Price awareness level; shapes how cost versus distance is weighted in ranking.
 * - distanceAcceptanceMeters: Exploration range in meters; how far the user is willing to walk (~200m = immediate, ~800m = ~10 min walk).
 * - typicalStayPreference: Default stay duration for filtering; removes spots with insufficient time limits.
 */
struct UserPreferences: Codable {
    var priceSensitivity: PriceSensitivity  // Shapes how cost vs. distance is weighted (thrifty favors cost, convenience favors proximity)
    var distanceAcceptanceMeters: Int  // Exploration range in meters (~200m = immediate, ~800m = ~10 min walk)
    var typicalStayPreference: StayTimePreference  // Default stay duration for filtering; removes spots with insufficient time limits
}
