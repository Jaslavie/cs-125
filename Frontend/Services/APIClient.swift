class APIClient {
    static let shared = APIClient()
    private let baseURL = "http://localhost:8000"  // FastAPI backend
    
    func searchParking(query: UserQuery, preferences: UserPreferences) async throws -> RankedResults {
        let url = URL(string: "\(baseURL)/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SearchRequest(query: query, preferences: preferences)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(RankedResults.self, from: data)
    }
}