import Foundation

/// Describes a GET request declaratively, so services read like the API docs.
public struct Endpoint: Sendable {
    public let baseURL: URL
    public let path: String
    public let queryItems: [URLQueryItem]
    public let timeout: TimeInterval

    public init(baseURL: URL, path: String, queryItems: [URLQueryItem] = [], timeout: TimeInterval = 15) {
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems
        self.timeout = timeout
    }

    func makeRequest() throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
