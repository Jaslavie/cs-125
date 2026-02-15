import Foundation
import CoreLocation

// MARK: - User query (per-search inputs)

/* Captures what the user enters for each parking search. The user enters their intended destination
 * and stay duration, while currentLocation and currentTime are auto-captured. This struct represents
 * a single parking search request with context-specific parameters.
 *
 * Attributes:
 * - targetLocation: Free-text destination string; geocoded to lat/lng by backend.
 * - currentLocation: User's current position from device GPS; wrapped in Codable Coordinate struct.
 * - currentTime: Timestamp when the query is processed; auto-captured and encoded as ISO 8601 for API.
 * - budgetRangePreference: Maximum total cost category for this specific search (per-query, not stored).
 * - stayTimePreference: Planned parking duration category for this specific search (per-query, not stored).
 */

// MARK: - Budget Range Preference

/* Maximum total cost the user is willing to pay for parking (category). Used for filtering and ranking.
 * Budget is a per-query input rather than a stored preference; users select this for each search.
 *
 * Attributes:
 * - low: $0–$10 total cost.
 * - medium: $10–$20 total cost.
 * - high: $20–$50 total cost.
 */
enum BudgetRangePreference: String, Codable, CaseIterable {
    case low     // $0–$10
    case medium  // $10–$20
    case high    // $20–$50
}

// MARK: - Stay Time Preference

/* How long the user plans to park. Filters out spots with inadequate time limits
 * (e.g., a 2-hour meter would be filtered out for a 4-hour stay). The user's habitual
 * parking length aids in eliminating unsuitable spots.
 *
 * Attributes:
 * - short: 0–60 min (quick errands, appointments).
 * - medium: 60–120 min (shopping, dining).
 * - long: 120–240 min (events, extended activities).
 */
enum StayTimePreference: String, Codable, CaseIterable {
    case short   // 0–60 min
    case medium  // 60–120 min
    case long    // 120–240 min
}

// MARK: - User Query

/* Full set of inputs for one parking search. Sent to the backend with currentTime encoded as ISO 8601.
 * Combines user-entered parameters (destination, budget, stay) with auto-captured context (location, time).
 *
 * Attributes:
 * - targetLocation: Free-text destination (e.g., "Pantages Theatre"); geocoded to lat/lng by backend.
 * - currentLocation: User's current position from device GPS; Codable via Coordinate wrapper.
 * - currentTime: Time at which the query is processed; auto-captured at search time.
 * - budgetRangePreference: Maximum total cost category for this search (low/medium/high).
 * - stayTimePreference: Planned parking duration category for this search (short/medium/long).
 */
struct UserQuery: Codable {
    let targetLocation: String  // Free-text destination (e.g., "Pantages Theatre"); geocoded to lat/lng by backend
    let currentLocation: Coordinate  // User's current position from device GPS; Codable via Coordinate wrapper
    let currentTime: Date  // Time at which the query is processed; auto-captured
    let budgetRangePreference: BudgetRangePreference  // Maximum total cost category for this search
    let stayTimePreference: StayTimePreference  // Planned parking duration category for this search
}
