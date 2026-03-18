import Foundation

// MARK: - Budget Range Preference

/* Budget range the user prefers for parking. Used for ranking.
 * Prioritizes parking spots with a final total price that correlates most closely to the chosen range.
 * Stored as part of the personal model in UserPreferences.
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

/* Range, in minutes, representing how long the user plans to park. 
 * Prioritizes parking spots with time limits that correlate most closely to the chosen range.
 * Stored as part of the personal model in UserPreferences.
 */
enum StayTimePreference: String, Codable, CaseIterable {
    case short   // 0–60 min
    case medium  // 60–120 min
    case long    // 120–240 min
}

// MARK: - User Preferences (stored personal model)

/* The personal framework comprises the user's budget and stay duration preferences that shape the
 * ranking process. Stored persistently across app sessions via SessionManager and applied to all
 * searches to provide personalized parking recommendations. Also embedded directly in UserQuery
 * so that per-search preference context travels with the query.
 *
 * Attributes:
 * - budgetRange: Budget category encoding price sensitivity (low $0–$10, medium $10–$20, high $20–$50).
 * - stayDuration: Stay duration category encoding intended parking length (short ≤1 hr, medium 1–2 hr, long 2–4 hr).
 */
struct UserPreferences: Codable {
    var budgetRange: BudgetRangePreference  // Budget category encoding price sensitivity (low $0–$10, medium $10–$20, high $20–$50)
    var stayDuration: StayTimePreference  // Stay duration category encoding intended parking length (short ≤1 hr, medium 1–2 hr, long 2–4 hr)
}
