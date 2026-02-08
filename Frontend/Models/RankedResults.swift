import Foundation

struct RankedResults: Codable {
    let spots: [ScoredSpot]             // a list of scored parking spots
    let totalCandidatesEvaluated: Int   // total number of parking spot candidates evaluated
    let queryTimestamp: Date            // the time instant when the query was given
}