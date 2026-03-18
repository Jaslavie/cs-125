import Foundation

/*
 * API client for the parking recommendation system.
 *
 * Attributes:
 * - shared: Singleton instance.
 * - useMockMode: When true, returns mock data instead of calling the backend.
 * - mockOccupancyOverrides: Per-spot occupancy state overrides used by the mock debug panel;
 *   only active when useMockMode is true.
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
     * Per-spot occupancy overrides used exclusively in mock mode. Keys are spaceids; values are
     * "VACANT", "OCCUPIED", or "UNKNOWN". Any spaceid not present defaults to "VACANT".
     * Populated by the mock debug panel in ResultsListView; resets on each new search for new parking meters.
     */
    var mockOccupancyOverrides: [String: String] = [:]

    /*
     * Clears all per-spot mock overrides, resetting every spot back to "VACANT".
     * Called by ParkingViewModel at the start of each new search so the debug panel
     * starts fresh against a new result set.
     */
    func resetMockOccupancyOverrides() {
        mockOccupancyOverrides = [:]
    }
    
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
     * Attempts to search for parking spots based on the user's query. If mock mode is enabled,
     * returns mock data instead of calling the backend. Throws an error if the composed URL is invalid
     * or if the HTTP response is not 200 OK. If successful, decodes the response as `RankedResults` and
     * returns the ranked results.
     *
     * Parameters:
     * - query: The user's query, including destination, location, timestamp, and preferences.
     *
     * Returns: a `RankedResults` object containing the ranked parking spots.
     */
    func searchParking(query: UserQuery) async throws -> RankedResults {
        if useMockMode {
            try await Task.sleep(nanoseconds: 800_000_000)  // Simulate network delay
            return Self.mockRankedResults
        }
        
        // Build query parameters for GET request; preferences are read from query.preferences
        var components = URLComponents(string: "\(baseURL)/meters/search")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(query.currentLocation.lat)),
            URLQueryItem(name: "lon", value: String(query.currentLocation.lng)),
            URLQueryItem(name: "destination", value: query.targetLocation),
            URLQueryItem(name: "budget", value: query.preferences.budgetRange.rawValue.uppercased()),
            URLQueryItem(name: "stay", value: query.preferences.stayDuration.rawValue.uppercased()),
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
    
    /*
     * Fetches the current real-time occupancy status for a list of parking space IDs.
     * Called on a polling interval to detect VACANT/OCCUPIED transitions. If mock mode is enabled,
     * returns mock data instead of calling the backend. Throws an error if the composed URL is invalid
     * or if the HTTP response is not 200 OK. If successful, decodes the response as a dictionary mapping
     * each spaceid to its occupancy string ("VACANT", "OCCUPIED", or "UNKNOWN").
     *
     * Parameters:
     * - spaceids: Array of space ID strings to query (e.g. ["HO108", "DT472"]).
     *
     * Returns: a dictionary mapping each spaceid to its occupancy string ("VACANT", "OCCUPIED", or "UNKNOWN").
     */
    func fetchOccupancy(spaceids: [String]) async throws -> [String: String] {
        if useMockMode {
            // Apply per-spot overrides from the debug panel; default unoverridden spots to "VACANT".
            return Dictionary(uniqueKeysWithValues: spaceids.map { id in
                (id, mockOccupancyOverrides[id] ?? "VACANT")
            })
        }
        
        var components = URLComponents(string: "\(baseURL)/meters/occupancy")!
        components.queryItems = [
            URLQueryItem(name: "spaceids", value: spaceids.joined(separator: ","))
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
        }
        
        return try jsonDecoder.decode([String: String].self, from: data)
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
