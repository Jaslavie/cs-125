import Foundation
import CoreLocation

// MARK: - User query (per-search inputs)
// Captures what the user enters for each parking search. Aligns with the proposal's "User Need → System Response":
// user enters intended destination and stay duration; currentLocation and currentTime are auto-captured.

// MARK: - Budget Range Preference
// Max total cost the user is willing to pay for parking (category). Used for filtering and ranking.
// Proposal: budget is a per-query input, not a stored preference.
enum BudgetRangePreference: String, Codable, CaseIterable {
    case low    // $0–$10
    case medium // $10–$20
    case high   // $20–$50
}

// MARK: - Stay Time Preference
// How long the user plans to park. Filters out spots with inadequate time limits (e.g. 2-hour meter for 4-hour stay).
// Proposal: "habitual parking length aids in eliminating unsuitable spots."
enum StayTimePreference: String, Codable, CaseIterable {
    case short  // 0–60 min
    case medium // 60–120 min
    case long   // 120–240 min
}

// MARK: - User Query
// Full set of inputs for one parking search. Sent to the backend; currentTime encoded as ISO 8601 for API.
struct UserQuery: Codable {
    /// Free-text destination (e.g. "Pantages Theatre"); geocoded to lat/lng by backend.
    let targetLocation: String
    /// User's current position from device GPS; Codable via Coordinate wrapper.
    let currentLocation: Coordinate
    /// Time at which the query is processed; auto-captured.
    let currentTime: Date
    /// Max total cost category for this search.
    let budgetRangePreference: BudgetRangePreference
    /// Planned parking duration category for this search.
    let stayTimePreference: StayTimePreference
}
