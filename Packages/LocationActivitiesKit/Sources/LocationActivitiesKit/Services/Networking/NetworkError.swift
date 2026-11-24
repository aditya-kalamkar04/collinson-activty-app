import Foundation

public enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case offline
    case timedOut
    case httpStatus(Int)
    case decoding(String)
    case transport(String)

    /// Folds the many `URLError` codes into the few cases the UI actually treats differently.
    init(urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            self = .offline
        case .timedOut:
            self = .timedOut
        default:
            self = .transport(urlError.localizedDescription)
        }
    }
}
