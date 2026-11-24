import Foundation

/// Builds the request, checks the status code, decodes JSON, and translates failures
/// into `NetworkError`. Every service shares this, so error handling lives in one place.
public struct APIClient: Sendable {
    private let http: any HTTPClient

    public init(http: any HTTPClient) {
        self.http = http
    }

    public func get<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        let request = try endpoint.makeRequest()

        let response: HTTPResponse
        do {
            response = try await http.send(request)
        } catch let error as URLError where error.code == .cancelled {
            // A cancelled task is not a failure the user needs to see.
            throw CancellationError()
        } catch let error as URLError {
            throw NetworkError(urlError: error)
        }

        guard (200..<300).contains(response.statusCode) else {
            throw NetworkError.httpStatus(response.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: response.data)
        } catch {
            throw NetworkError.decoding(String(describing: error))
        }
    }
}
