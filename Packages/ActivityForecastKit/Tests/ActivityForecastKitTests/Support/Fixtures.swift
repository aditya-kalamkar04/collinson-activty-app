import Foundation
@testable import ActivityForecastKit

extension City {
    static let london = City(
        id: 2_643_743, name: "London", region: "England", country: "United Kingdom",
        countryCode: "GB", latitude: 51.50853, longitude: -0.12574, elevation: 25,
        timeZoneIdentifier: "Europe/London"
    )
}

extension TimeZone {
    static let london = TimeZone(identifier: "Europe/London")!
}

extension DailyForecast {
    /// 2026-11-18 00:00 in London (GMT in November).
    static let referenceDate = Date(timeIntervalSince1970: 1_794_960_000)

    /// A mild, dry, calm, sunny day. Tests override only what they care about.
    static func make(
        dayOffset: Int = 0,
        condition: WeatherCondition = .clear,
        high: Double = 20,
        low: Double = 12,
        precipitation: Double = 0,
        precipitationProbability: Int? = 0,
        snowfall: Double = 0,
        wind: Double = 10,
        sunshineHours: Double = 9
    ) -> DailyForecast {
        DailyForecast(
            date: referenceDate.addingTimeInterval(TimeInterval(dayOffset) * 86_400),
            condition: condition,
            temperatureMax: high,
            temperatureMin: low,
            precipitationSum: precipitation,
            precipitationProbability: precipitationProbability,
            snowfallSum: snowfall,
            windSpeedMax: wind,
            sunshineDuration: sunshineHours * 3600
        )
    }
}

extension Forecast {
    static func week(_ day: DailyForecast = .make()) -> Forecast {
        let days = (0..<7).map { offset in
            DailyForecast(
                date: DailyForecast.referenceDate.addingTimeInterval(TimeInterval(offset) * 86_400),
                condition: day.condition,
                temperatureMax: day.temperatureMax,
                temperatureMin: day.temperatureMin,
                precipitationSum: day.precipitationSum,
                precipitationProbability: day.precipitationProbability,
                snowfallSum: day.snowfallSum,
                windSpeedMax: day.windSpeedMax,
                windGustsMax: day.windGustsMax,
                sunshineDuration: day.sunshineDuration
            )
        }
        return Forecast(timeZone: .london, days: days)
    }
}

/// Raw API payloads, trimmed copies of real Open-Meteo responses.
enum JSONFixtures {
    static let geocodingLondon = """
    {
      "results": [
        {
          "id": 2643743, "name": "London", "latitude": 51.50853, "longitude": -0.12574,
          "elevation": 25.0, "feature_code": "PPLC", "country_code": "GB",
          "admin1_id": 6269131, "timezone": "Europe/London", "population": 7556900,
          "country_id": 2635167, "country": "United Kingdom", "admin1": "England"
        },
        {
          "id": 6058560, "name": "London", "latitude": 42.98339, "longitude": -81.23304,
          "elevation": 252.0, "feature_code": "PPL", "country_code": "CA",
          "timezone": "America/Toronto", "country": "Canada", "admin1": "Ontario"
        }
      ],
      "generationtime_ms": 0.9
    }
    """

    /// Open-Meteo leaves out `results` entirely when nothing matches.
    static let geocodingNoResults = """
    { "generationtime_ms": 0.4 }
    """

    static let forecastLondon = """
    {
      "latitude": 51.5, "longitude": -0.12, "generationtime_ms": 0.2,
      "utc_offset_seconds": 0, "timezone": "Europe/London", "timezone_abbreviation": "GMT",
      "elevation": 23.0,
      "daily_units": { "time": "iso8601", "temperature_2m_max": "°C" },
      "daily": {
        "time": ["2026-11-18","2026-11-19","2026-11-20","2026-11-21","2026-11-22","2026-11-23","2026-11-24"],
        "weather_code": [3, 61, 80, 2, 0, 71, 95],
        "temperature_2m_max": [11.2, 9.8, 10.4, 8.1, 7.5, 1.2, 12.0],
        "temperature_2m_min": [6.1, 5.0, 4.4, 2.3, 0.4, -2.1, 8.0],
        "precipitation_sum": [0.0, 7.4, 3.1, 0.0, 0.0, 2.5, 15.2],
        "precipitation_probability_max": [10, 90, 65, 5, 0, 70, 95],
        "snowfall_sum": [0.0, 0.0, 0.0, 0.0, 0.0, 3.5, 0.0],
        "wind_speed_10m_max": [14.3, 28.1, 22.0, 11.5, 9.0, 18.4, 52.0],
        "wind_gusts_10m_max": [30.2, 55.0, 41.8, 22.3, 18.0, 33.1, 88.0],
        "sunshine_duration": [7200.0, 0.0, 3600.0, 21600.0, 25200.0, 1800.0, 0.0]
      }
    }
    """

    /// Day 2 has no temperature; day 3 has no wind (secondary value).
    static let forecastWithNulls = """
    {
      "utc_offset_seconds": 0, "timezone": "Europe/London",
      "daily": {
        "time": ["2026-11-18","2026-11-19","2026-11-20"],
        "weather_code": [0, 1, 2],
        "temperature_2m_max": [10.0, null, 12.0],
        "temperature_2m_min": [5.0, null, 6.0],
        "wind_speed_10m_max": [10.0, 12.0, null]
      }
    }
    """
}
