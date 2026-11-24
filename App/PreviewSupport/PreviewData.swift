#if DEBUG
import Foundation
import LocationActivitiesKit

/// Offline fakes for SwiftUI previews. The ranking preview runs the real scoring code on
/// made-up weather, so tweaking a scorer shows up in the canvas immediately.
enum PreviewData {
    static let london = City(
        id: 2_643_743, name: "London", region: "England", country: "United Kingdom",
        countryCode: "GB", latitude: 51.508, longitude: -0.126, timeZoneIdentifier: "Europe/London"
    )
    static let chamonix = City(
        id: 3_027_301, name: "Chamonix", region: "Auvergne-Rhône-Alpes", country: "France",
        countryCode: "FR", latitude: 45.924, longitude: 6.870, elevation: 1035,
        timeZoneIdentifier: "Europe/Paris"
    )

    static func week(startingAt start: Date = .now) -> [DailyForecast] {
        // Explicitly typed tables keep the type-checker fast and the preview readable.
        let conditions: [WeatherCondition] = [.clear, .partlyCloudy, .rain, .snow, .overcast, .thunderstorm, .clear]
        let highs: [Double] = [18, 21, 12, 0, 9, 16, 23]
        let lows: [Double] = [9, 11, 7, -4, 3, 10, 13]
        let rain: [Double] = [0, 0.4, 9, 6, 0.5, 14, 0]
        let rainChance: [Int] = [5, 15, 85, 70, 25, 90, 0]
        let snow: [Double] = [0, 0, 0, 12, 0, 0, 0]
        let wind: [Double] = [10, 14, 32, 22, 18, 48, 8]
        let sunshineHours: [Double] = [10, 7, 1, 2, 3, 0.5, 11]

        return conditions.indices.map { index in
            DailyForecast(
                date: Calendar.current.date(byAdding: .day, value: index, to: start) ?? start,
                condition: conditions[index],
                temperatureMax: highs[index],
                temperatureMin: lows[index],
                precipitationSum: rain[index],
                precipitationProbability: rainChance[index],
                snowfallSum: snow[index],
                windSpeedMax: wind[index],
                sunshineDuration: sunshineHours[index] * 3600
            )
        }
    }
}

struct PreviewCityRepository: CityRepository {
    func cities(matching query: String) async throws -> [City] {
        [PreviewData.london, PreviewData.chamonix]
            .filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

struct PreviewForecastRepository: ForecastRepository {
    func forecast(for city: City) async throws -> Forecast {
        Forecast(timeZone: .current, days: PreviewData.week())
    }
}

extension AppContainer {
    static let preview = AppContainer(
        searchCitiesUseCase: DefaultSearchCitiesUseCase(repository: PreviewCityRepository()),
        rankActivitiesUseCase: DefaultRankActivitiesUseCase(forecasts: PreviewForecastRepository())
    )
}
#endif
