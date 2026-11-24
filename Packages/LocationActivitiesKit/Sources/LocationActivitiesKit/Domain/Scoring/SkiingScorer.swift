import Foundation

/// Skiing wants fresh snow, cold enough to keep it, calm enough for lifts to run,
/// and enough visibility to see the piste.
///
/// Limitation: the daily forecast can't tell us how much snow is already on the ground,
/// so a cold, dry day at a resort with a deep base is under-rated. See DECISIONS.md.
public struct SkiingScorer: ActivityScoring {
    public var activity: Activity { .skiing }

    public init() {}

    public func assess(_ day: DailyForecast) -> DayAssessment {
        let freshSnow = ScoreCurve.ramp(day.snowfallSum, zeroAt: 0, oneAt: 10)
        let cold = ScoreCurve.ramp(day.temperatureMax, zeroAt: 6, oneAt: -2)
        let calm = ScoreCurve.ramp(day.windSpeedMax, zeroAt: 50, oneAt: 20)
        let visibility = Self.visibility(for: day.condition)

        var score = ScoreCurve.weightedScore([
            .init(value: freshSnow, weight: 0.35),
            .init(value: cold, weight: 0.30),
            .init(value: calm, weight: 0.20),
            .init(value: visibility, weight: 0.15)
        ])

        // No new snow and never below freezing: nothing to ski on, whatever the sunshine says.
        let noSnowPossible = day.snowfallSum < 0.5 && day.temperatureMin > 0
        if noSnowPossible {
            score = min(score, 10)
        }

        return DayAssessment(
            date: day.date,
            score: score,
            summary: Self.summary(for: day, noSnowPossible: noSnowPossible)
        )
    }

    private static func visibility(for condition: WeatherCondition) -> Double {
        switch condition {
        case .clear, .partlyCloudy: 1
        case .fog, .thunderstorm: 0
        default: 0.6
        }
    }

    private static func summary(for day: DailyForecast, noSnowPossible: Bool) -> String {
        let high = day.temperatureMax.wholeNumber
        if noSnowPossible {
            return "Too warm for snow, high of \(high)°"
        }
        if day.windSpeedMax >= 50 {
            return "Winds up to \(day.windSpeedMax.wholeNumber) km/h may close lifts"
        }
        if day.snowfallSum >= 1 {
            return "\(day.snowfallSum.wholeNumber) cm fresh snow, high of \(high)°"
        }
        return "No fresh snow, high of \(high)°"
    }
}
