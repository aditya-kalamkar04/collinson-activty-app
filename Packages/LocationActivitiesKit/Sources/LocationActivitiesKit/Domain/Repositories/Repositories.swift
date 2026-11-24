import Foundation

/// Domain-facing boundaries. The domain says *what* it needs; Services decide *how*
/// (Open-Meteo today, something else tomorrow, a stub in tests).

public protocol CityRepository: Sendable {
    func cities(matching query: String) async throws -> [City]
}

public protocol ForecastRepository: Sendable {
    func forecast(for city: City) async throws -> Forecast
}
