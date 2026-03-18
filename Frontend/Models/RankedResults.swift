import Foundation

// MARK: - Ranked Results

/* Represents the response from the backend search endpoint: a ranked list of recommended parking spots accompanied by candidate 
 * evaluation and query timestamp metadata. Contains an array of `ScoredSpot` objects (containing information needed for the results 
 * panel and map pins), the number of candidates evaluated before filtering and ranking, and the timestamp of the query prompting the 
 * ranked results to be delivered in the first place. Conforms to `Equatable` for use in `ParkingUIState`.
 *
 * Attributes:
 * - spots: Array of ranked `ScoredSpot` objects (best match first); consists of information needed for accurately displaying ranked 
            results info in the ranked results panel and map view pins.
 * - totalCandidatesEvaluated: Number of candidate spots considered before filtering and ranking (for transparency or debugging).
 * - queryTimestamp: ISO 8601 timestamp string when the query was processed by the backend.
 * - timestamp: Computed property; converts `queryTimestamp` string to `Date` for display or calculations.
 */
struct RankedResults: Codable, Equatable {
    let spots: [ScoredSpot]  // Ranked score cards (best match first)
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