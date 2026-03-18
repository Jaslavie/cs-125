import Foundation

// MARK: - User Query

/* Full set of inputs for one parking search. Combines user-entered parameters (destination,
 * preferences) with auto-captured context (device GPS location, timestamp). Sent to the backend
 * with currentTime encoded as ISO 8601. The preferences field embeds a UserPreferences value so
 * that budget and stay context travel are added to the query.
 *
 * Attributes:
 * - targetLocation: Free-text destination (e.g., "Pantages Theatre"); geocoded to lat/lng by backend.
 * - currentLocation: User's current position from device GPS; Codable via Coordinate wrapper.
 * - currentTime: Timestamp auto-captured at search time; encoded as ISO 8601 for the API.
 * - preferences: Budget range and stay duration for this search; sourced from SessionManager.
 */
struct UserQuery: Codable {
    let targetLocation: String  // Free-text destination (e.g., "Pantages Theatre"); geocoded to lat/lng by backend
    let currentLocation: Coordinate  // User's current position from device GPS; Codable via Coordinate wrapper
    let currentTime: Date  // Time at which the query is processed; auto-captured
    let preferences: UserPreferences  // Budget range and stay duration for this search
}
