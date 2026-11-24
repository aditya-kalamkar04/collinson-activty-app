import Foundation

/// One day of forecast, already converted into domain units:
/// temperatures in °C, precipitation in mm, snowfall in cm, wind in km/h.
public struct DailyForecast: Identifiable, Equatable, Sendable {
    public var id: Date { date }

    /// Start of the day in the location's own time zone.
    public let date: Date
    public let condition: WeatherCondition
    public let temperatureMax: Double
    public let temperatureMin: Double
    public let precipitationSum: Double
    /// Highest hourly chance of precipitation that day, 0–100. Not every model provides it.
    public let precipitationProbability: Int?
    public let snowfallSum: Double
    public let windSpeedMax: Double
    public let windGustsMax: Double?
    /// Seconds of sunshine.
    public let sunshineDuration: TimeInterval

    public init(
        date: Date,
        condition: WeatherCondition,
        temperatureMax: Double,
        temperatureMin: Double,
        precipitationSum: Double = 0,
        precipitationProbability: Int? = nil,
        snowfallSum: Double = 0,
        windSpeedMax: Double = 0,
        windGustsMax: Double? = nil,
        sunshineDuration: TimeInterval = 0
    ) {
        self.date = date
        self.condition = condition
        self.temperatureMax = temperatureMax
        self.temperatureMin = temperatureMin
        self.precipitationSum = precipitationSum
        self.precipitationProbability = precipitationProbability
        self.snowfallSum = snowfallSum
        self.windSpeedMax = windSpeedMax
        self.windGustsMax = windGustsMax
        self.sunshineDuration = sunshineDuration
    }

    public var sunshineHours: Double { sunshineDuration / 3600 }
}

/// A multi-day forecast and the time zone its dates are expressed in.
public struct Forecast: Equatable, Sendable {
    public let timeZone: TimeZone
    public let days: [DailyForecast]

    public init(timeZone: TimeZone, days: [DailyForecast]) {
        self.timeZone = timeZone
        self.days = days
    }
}
