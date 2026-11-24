import Foundation

/// A good day for walking around: comfortable temperature, dry, not too windy, decent sky.
public struct OutdoorSightseeingScorer: ActivityScoring {
    public var activity: Activity { .outdoorSightseeing }

    public init() {}

    public func assess(_ day: DailyForecast) -> DayAssessment {
        let comfort = ScoreCurve.band(day.temperatureMax, ideal: 16...26, tolerance: 12)
        let lowRainChance: Double = if let probability = day.precipitationProbability {
            ScoreCurve.ramp(Double(probability), zeroAt: 80, oneAt: 10)
        } else {
            // Some models don't publish probability; fall back to the expected amount.
            ScoreCurve.ramp(day.precipitationSum, zeroAt: 8, oneAt: 0)
        }
        let lowRainAmount = ScoreCurve.ramp(day.precipitationSum, zeroAt: 10, oneAt: 0)
        let calm = ScoreCurve.ramp(day.windSpeedMax, zeroAt: 45, oneAt: 15)
        let sky = Self.skyQuality(for: day.condition)

        var score = ScoreCurve.weightedScore([
            .init(value: comfort, weight: 0.30),
            .init(value: lowRainChance, weight: 0.20),
            .init(value: lowRainAmount, weight: 0.15),
            .init(value: calm, weight: 0.15),
            .init(value: sky, weight: 0.20)
        ])

        if day.condition == .thunderstorm {
            score = min(score, 15)
        }

        return DayAssessment(date: day.date, score: score, summary: Self.summary(for: day))
    }

    private static func skyQuality(for condition: WeatherCondition) -> Double {
        switch condition {
        case .clear: 1
        case .partlyCloudy: 0.9
        case .overcast: 0.6
        case .fog: 0.4
        case .drizzle: 0.3
        case .snow, .snowShowers: 0.2
        case .rain, .showers, .freezingRain: 0.15
        case .thunderstorm: 0
        case .unknown: 0.5
        }
    }

    private static func summary(for day: DailyForecast) -> String {
        var summary = "\(day.condition.description), high of \(day.temperatureMax.wholeNumber)°"
        if let probability = day.precipitationProbability, probability >= 50 {
            summary += ", \(probability)% chance of rain"
        }
        return summary
    }
}
