import Foundation

// MARK: - User Preferences (stored personal model)

/* The personal framework tracks the user's budget and stay duration preferences that shape the ranking process.
 * These preferences are stored persistently across app sessions and applied to all searches to provide
 * personalized parking recommendations based on the user's spending power and typical parking habits.
 *
 * Attributes:
 * - budgetRange: Budget category encoding price sensitivity (low $0–$10, medium $10–$20, high $20–$50).
 * - stayDuration: Stay duration category encoding typical parking length habits (short ≤1 hr, medium 1–2 hr, long 2–4 hr).
 */
struct UserPreferences: Codable {
    var budgetRange: BudgetRangePreference  // Budget category encoding price sensitivity (low $0–$10, medium $10–$20, high $20–$50)
    var stayDuration: StayTimePreference  // Stay duration category encoding typical parking length (short ≤1 hr, medium 1–2 hr, long 2–4 hr)
}
