import Foundation

// MARK: - Search Request

/* Deprecated request body struct originally used for POST requests. Kept for potential future use.
 * Note: UserQuery now embeds UserPreferences directly, so the preferences field here is redundant
 * in the current GET-based implementation. The current flow uses GET /meters/search with URL
 * query parameters derived from UserQuery (including query.preferences).
 *
 * Attributes:
 * - query: UserQuery containing per-search inputs (destination, location, time, and preferences).
 * - preferences: UserPreferences stored personal model (budget range, stay duration).
 */
struct SearchRequest: Codable {
    let query: UserQuery  // Per-search inputs (destination, location, time)
    let preferences: UserPreferences  // Stored personal model (budget range, stay duration)
}
