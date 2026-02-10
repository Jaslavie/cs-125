import Foundation

// MARK: - Search Request
// Request body sent to the backend search endpoint. Combines per-query inputs (UserQuery)
// with the user's stored personal model (UserPreferences) so the ranking engine can produce
// a context-aware ranked list of parking spots.
struct SearchRequest: Codable {
    let query: UserQuery
    let preferences: UserPreferences
}
