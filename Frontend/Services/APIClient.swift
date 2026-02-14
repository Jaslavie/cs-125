import Foundation

class APIClient {
    static let shared = APIClient()
    private let baseURL = "http://localhost:8000"  // FastAPI backend
    
    /// When true, returns mock data instead of calling the backend.
    var useMockMode: Bool = true
    
    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    func searchParking(query: UserQuery, preferences: UserPreferences) async throws -> RankedResults {
        if useMockMode {
            try await Task.sleep(nanoseconds: 800_000_000)  // Simulate network delay
            return Self.mockRankedResults
        }
        
        let url = URL(string: "\(baseURL)/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SearchRequest(query: query, preferences: preferences)
        request.httpBody = try jsonEncoder.encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try jsonDecoder.decode(RankedResults.self, from: data)
    }
    
    // MARK: - Mock Data
    
    static let mockRankedResults: RankedResults = RankedResults(
        spots: [
            ScoredSpot(
                spaceid: "HO108",
                meterAddress: "6233 Hollywood Blvd",
                latitude: 34.1017,
                longitude: -118.3261,
                walkTime: 3,
                rate: 2.00,
                estimatedTotalCost: 6.00,
                timelimit: 240,
                rank: 1,
                colorCode: .green
            ),
            ScoredSpot(
                spaceid: "DT472",
                meterAddress: "400 Spring St",
                latitude: 34.0516,
                longitude: -118.2492,
                walkTime: 5,
                rate: 1.50,
                estimatedTotalCost: 4.50,
                timelimit: 240,
                rank: 2,
                colorCode: .green
            ),
            ScoredSpot(
                spaceid: "HO829",
                meterAddress: "6350 Vine St",
                latitude: 34.0998,
                longitude: -118.3285,
                walkTime: 2,
                rate: 3.00,
                estimatedTotalCost: 9.00,
                timelimit: 600,
                rank: 3,
                colorCode: .yellow
            ),
            ScoredSpot(
                spaceid: "DT940",
                meterAddress: "500 Broadway",
                latitude: 34.0492,
                longitude: -118.2510,
                walkTime: 4,
                rate: 2.50,
                estimatedTotalCost: 7.50,
                timelimit: 480,
                rank: 4,
                colorCode: .yellow
            ),
            ScoredSpot(
                spaceid: "HO920",
                meterAddress: "1620 N Cherokee Ave",
                latitude: 34.0985,
                longitude: -118.3312,
                walkTime: 8,
                rate: 1.25,
                estimatedTotalCost: 3.75,
                timelimit: 120,
                rank: 5,
                colorCode: .orange
            )
        ],
        totalCandidatesEvaluated: 12,
        queryTimestamp: Date()
    )
}
