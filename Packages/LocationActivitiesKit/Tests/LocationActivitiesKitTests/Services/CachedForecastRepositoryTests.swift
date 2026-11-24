import Foundation
import Testing
@testable import LocationActivitiesKit

@Suite("CachedForecastRepository")
struct CachedForecastRepositoryTests {
    @Test("A repeat request inside the TTL is served from memory")
    func cachesWithinTTL() async throws {
        let upstream = ForecastRepositorySpy(result: .success(.week()))
        let clock = TestClock()
        let sut = CachedForecastRepository(upstream: upstream, timeToLive: 900, now: { clock.now })

        _ = try await sut.forecast(for: .london)
        clock.advance(by: 899)
        _ = try await sut.forecast(for: .london)

        #expect(await upstream.callCount == 1)
    }

    @Test("An expired entry is fetched again")
    func refetchesAfterTTL() async throws {
        let upstream = ForecastRepositorySpy(result: .success(.week()))
        let clock = TestClock()
        let sut = CachedForecastRepository(upstream: upstream, timeToLive: 900, now: { clock.now })

        _ = try await sut.forecast(for: .london)
        clock.advance(by: 901)
        _ = try await sut.forecast(for: .london)

        #expect(await upstream.callCount == 2)
    }

    @Test("Concurrent requests for the same city share one upstream call")
    func coalescesInFlightRequests() async throws {
        let upstream = ForecastRepositorySpy(result: .success(.week()), delay: .milliseconds(50))
        let sut = CachedForecastRepository(upstream: upstream)

        async let first = sut.forecast(for: .london)
        async let second = sut.forecast(for: .london)
        let (a, b) = try await (first, second)

        #expect(a == b)
        #expect(await upstream.callCount == 1)
    }

    @Test("Failures are not cached")
    func doesNotCacheFailures() async throws {
        let upstream = ForecastRepositorySpy(result: .failure(NetworkError.offline))
        let sut = CachedForecastRepository(upstream: upstream)

        await #expect(throws: NetworkError.offline) {
            try await sut.forecast(for: .london)
        }

        await upstream.setResult(.success(.week()))
        let forecast = try await sut.forecast(for: .london)

        #expect(forecast.days.count == 7)
        #expect(await upstream.callCount == 2)
    }

    @Test("removeAll forces a fresh fetch")
    func removeAll() async throws {
        let upstream = ForecastRepositorySpy(result: .success(.week()))
        let sut = CachedForecastRepository(upstream: upstream)

        _ = try await sut.forecast(for: .london)
        await sut.removeAll()
        _ = try await sut.forecast(for: .london)

        #expect(await upstream.callCount == 2)
    }
}
