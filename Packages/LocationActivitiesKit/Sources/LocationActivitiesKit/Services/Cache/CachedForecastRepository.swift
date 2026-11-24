import Foundation

/// Decorates any `ForecastRepository` with a short-lived in-memory cache and
/// request coalescing.
///
/// Why an actor: two screens (or a fast back-and-forth) can ask for the same city at the
/// same moment. The actor serialises access to `entries`, and storing the in-flight
/// `Task` *before* awaiting it means a second caller joins the first request instead of
/// firing another one. The entry is written before the first suspension point, so actor
/// re-entrancy can't let a duplicate request slip through.
public actor CachedForecastRepository: ForecastRepository {
    private enum Entry {
        case inFlight(Task<Forecast, any Error>)
        case cached(Forecast, fetchedAt: Date)
    }

    private let upstream: any ForecastRepository
    private let timeToLive: TimeInterval
    private let now: @Sendable () -> Date
    private var entries: [City.ID: Entry] = [:]

    /// Open-Meteo updates its models roughly hourly; 15 minutes keeps navigation snappy
    /// without showing stale data for long.
    public init(
        upstream: any ForecastRepository,
        timeToLive: TimeInterval = 15 * 60,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.upstream = upstream
        self.timeToLive = timeToLive
        self.now = now
    }

    public func forecast(for city: City) async throws -> Forecast {
        switch entries[city.id] {
        case .some(.cached(let forecast, let fetchedAt)) where now().timeIntervalSince(fetchedAt) < timeToLive:
            return forecast
        case .some(.inFlight(let task)):
            return try await task.value
        default:
            break
        }

        let upstream = self.upstream
        let task = Task { try await upstream.forecast(for: city) }
        entries[city.id] = .inFlight(task)

        do {
            let forecast = try await task.value
            entries[city.id] = .cached(forecast, fetchedAt: now())
            return forecast
        } catch {
            // Never cache failures: the next attempt should really try again.
            entries[city.id] = nil
            throw error
        }
    }

    /// Drops everything, e.g. for an explicit pull-to-refresh.
    public func removeAll() {
        entries.removeAll()
    }
}
