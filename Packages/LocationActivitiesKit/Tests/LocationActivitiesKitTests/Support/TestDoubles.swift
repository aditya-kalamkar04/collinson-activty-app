import Foundation
@testable import LocationActivitiesKit

// MARK: - Networking

/// Records every request and replies with a canned response or error.
actor MockHTTPClient: HTTPClient {
    private(set) var requests: [URLRequest] = []
    private let result: Result<HTTPResponse, any Error>

    init(statusCode: Int = 200, body: String) {
        result = .success(HTTPResponse(statusCode: statusCode, data: Data(body.utf8)))
    }

    init(error: any Error) {
        result = .failure(error)
    }

    func send(_ request: URLRequest) async throws -> HTTPResponse {
        requests.append(request)
        return try result.get()
    }

    var lastQueryItems: [String: String] {
        guard
            let url = requests.last?.url,
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { return [:] }
        return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last })
    }
}

// MARK: - Repositories

actor CityRepositorySpy: CityRepository {
    private(set) var receivedQueries: [String] = []
    private let result: Result<[City], any Error>

    init(result: Result<[City], any Error> = .success([])) {
        self.result = result
    }

    func cities(matching query: String) async throws -> [City] {
        receivedQueries.append(query)
        return try result.get()
    }
}

actor ForecastRepositorySpy: ForecastRepository {
    private(set) var callCount = 0
    private var result: Result<Forecast, any Error>
    private let delay: Duration

    init(result: Result<Forecast, any Error>, delay: Duration = .zero) {
        self.result = result
        self.delay = delay
    }

    func setResult(_ result: Result<Forecast, any Error>) {
        self.result = result
    }

    func forecast(for city: City) async throws -> Forecast {
        callCount += 1
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        return try result.get()
    }
}

// MARK: - Use cases

actor SearchCitiesUseCaseSpy: SearchCitiesUseCase {
    private(set) var receivedQueries: [String] = []
    private let result: Result<[City], any Error>

    init(result: Result<[City], any Error>) {
        self.result = result
    }

    func execute(query: String) async throws -> [City] {
        receivedQueries.append(query)
        return try result.get()
    }
}

actor RankActivitiesUseCaseSpy: RankActivitiesUseCase {
    private(set) var callCount = 0
    private let result: Result<ActivityReport, any Error>

    init(result: Result<ActivityReport, any Error>) {
        self.result = result
    }

    func execute(for city: City) async throws -> ActivityReport {
        callCount += 1
        return try result.get()
    }
}

// MARK: - Time

/// A clock the test can move forward by hand.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ start: Date = Date(timeIntervalSince1970: 1_800_000_000)) {
        current = start
    }

    var now: Date {
        lock.withLock { current }
    }

    func advance(by seconds: TimeInterval) {
        lock.withLock { current.addTimeInterval(seconds) }
    }
}

struct StubError: Error, Equatable {}
