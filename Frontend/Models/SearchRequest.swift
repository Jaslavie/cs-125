import Foundation

// MARK: - Search Request

/* Request body sent to the backend search endpoint. Combines per-query inputs (UserQuery)
 * with the user's stored personal model (UserPreferences) so the ranking engine can produce
 * a context-aware ranked list of parking spots.
 *
 * Note: This struct was used for POST requests in the original design but is now deprecated.
 * The current implementation uses GET requests with URL query parameters instead. This struct
 * is kept for potential future use or backward compatibility.
 *
 * Attributes:
 * - query: UserQuery containing per-search inputs (destination, location, time, budget, stay).
 * - preferences: UserPreferences containing stored personal model (budget range, stay duration).
 */
struct SearchRequest: Codable {
    let query: UserQuery  // Per-search inputs (destination, location, time)
    let preferences: UserPreferences  // Stored personal model (budget range, stay duration)
}
