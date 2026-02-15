import Foundation

// MARK: - Ranked Results

/* Response from the backend search containing the ordered list of recommended parking spots.
 * The system delivers a ranked list of optimal parking spots near the user's desired location,
 * typically 5–8 options. Conforms to Equatable for ParkingUIState so the view model can compare
 * state changes and trigger UI updates.
 *
 * Attributes:
 * - spots: Array of ranked ScoredSpot objects (best match first); shown in the results panel and as pins on the map.
 * - totalCandidatesEvaluated: Number of candidate spots considered before filtering and ranking (for transparency or debugging).
 * - queryTimestamp: ISO 8601 timestamp string when the query was processed by the backend.
 * - timestamp: Computed property; converts queryTimestamp string to Date for display or calculations.
 */
struct RankedResults: Codable, Equatable {
    let spots: [ScoredSpot]  // Ranked score cards (best match first); shown in results panel and as map pins
    let totalCandidatesEvaluated: Int  // Number of candidate spots considered before filtering and ranking
    let queryTimestamp: String  // ISO 8601 timestamp string from backend when query was processed
    
    /* 
     * CodingKeys for mapping backend JSON field names (snake_case) to Swift property names (camelCase).
     * Backend returns: total_candidates_evaluated, query_timestamp.
     * Swift uses: totalCandidatesEvaluated, queryTimestamp.
     */
    enum CodingKeys: String, CodingKey {
        case spots
        case totalCandidatesEvaluated = "total_candidates_evaluated"
        case queryTimestamp = "query_timestamp"
    }
    
    /*
     * Computed property to convert timestamp string to Date.
     * Parses the ISO 8601 timestamp from the backend for display or time-based calculations.
     *
     * Returns: Optional Date; nil if parsing fails.
     */
    var timestamp: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: queryTimestamp)
    }
}