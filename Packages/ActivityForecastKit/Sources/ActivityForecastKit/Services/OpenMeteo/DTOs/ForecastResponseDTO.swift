import Foundation

/// Mirrors the `daily` block of https://api.open-meteo.com/v1/forecast
///
/// Open-Meteo returns parallel arrays (one array per variable, indexed by day) and any
/// element can be `null`. Everything except `time` is optional so one missing variable
/// doesn't fail the whole decode; the mapper decides what is actually required.
struct ForecastResponseDTO: Decodable, Sendable {
    let timezone: String
    let utcOffsetSeconds: Int?
    let daily: Daily

    enum CodingKeys: String, CodingKey {
        case timezone, daily
        case utcOffsetSeconds = "utc_offset_seconds"
    }

    struct Daily: Decodable, Sendable {
        let time: [String]
        let weatherCode: [Int?]?
        let temperatureMax: [Double?]?
        let temperatureMin: [Double?]?
        let precipitationSum: [Double?]?
        let precipitationProbabilityMax: [Double?]?
        let snowfallSum: [Double?]?
        let windSpeedMax: [Double?]?
        let windGustsMax: [Double?]?
        let sunshineDuration: [Double?]?

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperatureMax = "temperature_2m_max"
            case temperatureMin = "temperature_2m_min"
            case precipitationSum = "precipitation_sum"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case snowfallSum = "snowfall_sum"
            case windSpeedMax = "wind_speed_10m_max"
            case windGustsMax = "wind_gusts_10m_max"
            case sunshineDuration = "sunshine_duration"
        }
    }
}
