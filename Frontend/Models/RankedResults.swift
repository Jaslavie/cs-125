import Foundation

// MARK: - Ranked Results
// Response from the backend search: the ordered list of recommended parking spots.
// Proposal: "The system then delivers a ranked list of optimal parking spots near the user's
// desired location"; typically 5–8 options. Conforms to Equatable for ParkingUIState.
struct RankedResults: Codable, Equatable {
    /// Ranked score cards (best match first). Shown in the results panel and as pins on the map.
    let spots: [ScoredSpot]
    /// Number of candidate spots considered before filtering/ranking (for transparency or debugging).
    let totalCandidatesEvaluated: Int
    /// Time the query was processed (matches UserQuery.currentTime).
    let queryTimestamp: Date
}