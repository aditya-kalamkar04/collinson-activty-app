import Foundation

enum ForecastMapper {
    static func map(_ dto: ForecastResponseDTO) -> Forecast {
        let timeZone = TimeZone(identifier: dto.timezone)
            ?? dto.utcOffsetSeconds.flatMap { TimeZone(secondsFromGMT: $0) }
            ?? TimeZone(secondsFromGMT: 0)!

        // "2026-11-18" is a calendar day in the *location's* time zone, not the device's.
        let parser = DateFormatter()
        parser.calendar = Calendar(identifier: .gregorian)
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = timeZone
        parser.dateFormat = "yyyy-MM-dd"

        let daily = dto.daily
        let days = daily.time.indices.compactMap { index -> DailyForecast? in
            // Without a condition and temperatures we can't score a day honestly, so we drop it
            // rather than invent values. Secondary values default to "none" (0).
            guard
                let date = parser.date(from: daily.time[index]),
                let code = element(daily.weatherCode, at: index),
                let high = element(daily.temperatureMax, at: index),
                let low = element(daily.temperatureMin, at: index)
            else {
                return nil
            }

            return DailyForecast(
                date: date,
                condition: WeatherCondition(wmoCode: code),
                temperatureMax: high,
                temperatureMin: low,
                precipitationSum: element(daily.precipitationSum, at: index) ?? 0,
                precipitationProbability: element(daily.precipitationProbabilityMax, at: index)
                    .map { Int($0.rounded()) },
                snowfallSum: element(daily.snowfallSum, at: index) ?? 0,
                windSpeedMax: element(daily.windSpeedMax, at: index) ?? 0,
                windGustsMax: element(daily.windGustsMax, at: index),
                sunshineDuration: element(daily.sunshineDuration, at: index) ?? 0
            )
        }

        return Forecast(timeZone: timeZone, days: days)
    }

    /// Safe lookup into one of Open-Meteo's parallel arrays.
    private static func element<Value>(_ values: [Value?]?, at index: Int) -> Value? {
        guard let values, values.indices.contains(index) else { return nil }
        return values[index]
    }
}
