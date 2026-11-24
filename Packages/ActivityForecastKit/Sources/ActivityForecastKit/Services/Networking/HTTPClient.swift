import Foundation

/// A transport-level response. Our own Sendable type, so nothing non-Sendable
/// (like `URLResponse`) has to cross concurrency boundaries.
public struct HTTPResponse: Sendable {
    public let statusCode: Int
    public let data: Data

    public init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }
}

/// The one seam between the app and the network. Tests swap in an actor-backed fake.
public protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPResponse
}

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        return HTTPResponse(statusCode: httpResponse.statusCode, data: data)
    }
}
