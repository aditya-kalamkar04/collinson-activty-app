import Foundation

public protocol RankActivitiesUseCase: Sendable {
    func execute(for city: City) async throws -> ActivityReport
}

/// Fetches the forecast, scores every day for every activity, and ranks the activities.
///
/// The weekly score is the plain mean of the daily scores. That is easy to explain and
/// rewards consistency. Its weakness, one perfect powder day in an otherwise poor week
/// still ranks low, is why the UI shows each activity's best day prominently.
public struct DefaultRankActivitiesUseCase: RankActivitiesUseCase {
    private let forecasts: any ForecastRepository
    private let scorers: [any ActivityScoring]

    public init(
        forecasts: any ForecastRepository,
        scorers: [any ActivityScoring] = DefaultRankActivitiesUseCase.standardScorers
    ) {
        self.forecasts = forecasts
        self.scorers = scorers
    }

    public static var standardScorers: [any ActivityScoring] {
        let outdoor = OutdoorSightseeingScorer()
        return [
            SkiingScorer(),
            SurfingScorer(),
            outdoor,
            IndoorSightseeingScorer(outdoor: outdoor)
        ]
    }

    public func execute(for city: City) async throws -> ActivityReport {
        let forecast = try await forecasts.forecast(for: city)
        guard !forecast.days.isEmpty else { throw DomainError.noForecastAvailable }

        let rankings = scorers
            .map { Self.rank($0, over: forecast.days) }
            .sorted(by: Self.isRankedHigher)

        return ActivityReport(
            city: city,
            timeZone: forecast.timeZone,
            days: forecast.days,
            rankings: rankings
        )
    }

    static func rank(_ scorer: any ActivityScoring, over days: [DailyForecast]) -> ActivityRanking {
        let assessments = days.map { scorer.assess($0) }
        let total = assessments.reduce(0) { $0 + $1.score }
        let average = assessments.isEmpty
            ? 0
            : Int((Double(total) / Double(assessments.count)).rounded())
        return ActivityRanking(activity: scorer.activity, score: average, days: assessments)
    }

    static func isRankedHigher(_ lhs: ActivityRanking, _ rhs: ActivityRanking) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        return lhs.activity.sortIndex < rhs.activity.sortIndex
    }
}
