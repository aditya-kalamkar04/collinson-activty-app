import Foundation

/// Museums and galleries are open whatever the weather, so indoor sightseeing never
/// scores badly. It becomes the *better* choice as the outdoors gets worse, which is what
/// a ranking should express. Scores land in roughly 50...90.
///
/// Built on top of the outdoor scorer so the two can never disagree about what "bad
/// weather" means.
public struct IndoorSightseeingScorer: ActivityScoring {
    public var activity: Activity { .indoorSightseeing }

    private let outdoor: OutdoorSightseeingScorer

    public init(outdoor: OutdoorSightseeingScorer = OutdoorSightseeingScorer()) {
        self.outdoor = outdoor
    }

    public func assess(_ day: DailyForecast) -> DayAssessment {
        let outdoorScore = outdoor.assess(day).score
        var score = 50 + Int((Double(100 - outdoorScore) * 0.4).rounded())

        // Storms or heavy snow make getting between venues harder.
        let travelIsHard = day.condition == .thunderstorm || day.snowfallSum >= 15
        if travelIsHard {
            score -= 10
        }

        let summary = outdoorScore < 40
            ? "Good day for museums, \(day.condition.description.lowercased()) outside"
            : "Always an option, but it's pleasant outside"

        return DayAssessment(date: day.date, score: ScoreCurve.clamp(score), summary: summary)
    }
}
