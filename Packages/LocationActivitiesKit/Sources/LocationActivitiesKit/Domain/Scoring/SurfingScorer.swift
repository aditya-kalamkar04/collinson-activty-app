import Foundation

/// Rates the *weather* for a surf session: light winds for a clean surface, warm air,
/// little rain, some sun, and no lightning.
///
/// Limitation: the Forecast API has no swell or wave data, and we don't know whether the
/// place is on a coast. This score answers "is it a nice day to be in the sea?", not
/// "are there waves?". Open-Meteo's Marine API is the natural next step. See DECISIONS.md.
public struct SurfingScorer: ActivityScoring {
    public var activity: Activity { .surfing }

    public init() {}

    public func assess(_ day: DailyForecast) -> DayAssessment {
        let lightWind = ScoreCurve.ramp(day.windSpeedMax, zeroAt: 40, oneAt: 12)
        let warmth = ScoreCurve.ramp(day.temperatureMax, zeroAt: 8, oneAt: 24)
        let dry = ScoreCurve.ramp(day.precipitationSum, zeroAt: 10, oneAt: 0)
        let sunny = ScoreCurve.ramp(day.sunshineHours, zeroAt: 0, oneAt: 8)

        var score = ScoreCurve.weightedScore([
            .init(value: lightWind, weight: 0.40),
            .init(value: warmth, weight: 0.25),
            .init(value: dry, weight: 0.20),
            .init(value: sunny, weight: 0.15)
        ])

        // Lightning and open water don't mix; this is a safety cap, not a preference.
        if day.condition == .thunderstorm {
            score = min(score, 5)
        }

        return DayAssessment(date: day.date, score: score, summary: Self.summary(for: day))
    }

    private static func summary(for day: DailyForecast) -> String {
        let wind = day.windSpeedMax.wholeNumber
        let high = day.temperatureMax.wholeNumber
        if day.condition == .thunderstorm {
            return "Thunderstorms, stay out of the water"
        }
        if day.windSpeedMax >= 40 {
            return "Blown out, winds up to \(wind) km/h"
        }
        if day.windSpeedMax <= 15 {
            return "Light winds (\(wind) km/h), high of \(high)°"
        }
        return "Breezy (\(wind) km/h), high of \(high)°"
    }
}
