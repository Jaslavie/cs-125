import Foundation

/*
 * API client for the parking recommendation system.
 *
 * Attributes:
 * - shared: Singleton instance.
 * - useMockMode: When true, returns mock data instead of calling the backend.
 * - jsonEncoder: JSON encoder for encoding dates as ISO 8601.
 * - jsonDecoder: JSON decoder for decoding dates from ISO 8601.
 */
class APIClient {
    static let shared = APIClient()
    private let baseURL = "http://localhost:8000"  // FastAPI backend
    
    /*
     * When true, returns mock data instead of calling the backend.
     */
    var useMockMode: Bool = false
    
    /*
     * JSON encoder for encoding dates as ISO 8601.
     */
    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    /*
     * JSON decoder for decoding dates from ISO 8601.
     */
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    /*
     * Searches for parking spots based on the user's query and preferences.
     *
     * Parameters:
     * - query: The user's query.
     * - preferences: The user's preferences.
     *
     * Returns: The ranked results.
     */
    func searchParking(query: UserQuery, preferences: UserPreferences) async throws -> RankedResults {
        if useMockMode {
            try await Task.sleep(nanoseconds: 800_000_000)  // Simulate network delay
            return Self.mockRankedResults
        }
        
        // Build query parameters for GET request
        var components = URLComponents(string: "\(baseURL)/meters/search")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(query.currentLocation.lat)),
            URLQueryItem(name: "lon", value: String(query.currentLocation.lng)),
            URLQueryItem(name: "destination", value: query.targetLocation),
            URLQueryItem(name: "budget", value: query.budgetRangePreference.rawValue.uppercased()),
            URLQueryItem(name: "stay", value: query.stayTimePreference.rawValue.uppercased()),
            URLQueryItem(name: "top_k", value: "10")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse {
            guard (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
        }
        
        return try jsonDecoder.decode(RankedResults.self, from: data)
    }
    
    // MARK: - Mock Data
    
    /*
     * Mock ranked results for testing.
     */
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
                colorCode: .green,
                occupancy: "VACANT"
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
                colorCode: .green,
                occupancy: "VACANT"
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
                colorCode: .green,
                occupancy: "VACANT"
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
                colorCode: .yellow,
                occupancy: "VACANT"
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
                colorCode: .yellow,
                occupancy: "UNKNOWN"
            )
        ],
        totalCandidatesEvaluated: 12,
        queryTimestamp: ISO8601DateFormatter().string(from: Date())
    )
}
