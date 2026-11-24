import Foundation

/// How suitable a single day is for one activity.
public struct DayAssessment: Equatable, Sendable {
    public let date: Date
    /// 0 (don't bother) to 100 (ideal).
    public let score: Int
    /// One short, human reason for the score, e.g. "12 cm fresh snow, high of -3°".
    public let summary: String

    public init(date: Date, score: Int, summary: String) {
        self.date = date
        self.score = score
        self.summary = summary
    }
}

public enum SuitabilityRating: Equatable, Sendable, CaseIterable {
    case excellent
    case good
    case fair
    case poor

    public init(score: Int) {
        switch score {
        case 75...: self = .excellent
        case 55..<75: self = .good
        case 35..<55: self = .fair
        default: self = .poor
        }
    }

    public var title: String {
        switch self {
        case .excellent: "Excellent"
        case .good: "Good"
        case .fair: "Fair"
        case .poor: "Poor"
        }
    }
}

/// One activity's verdict for the whole forecast window.
public struct ActivityRanking: Identifiable, Equatable, Sendable {
    public let activity: Activity
    /// Mean of the daily scores, 0–100.
    public let score: Int
    public let days: [DayAssessment]

    public init(activity: Activity, score: Int, days: [DayAssessment]) {
        self.activity = activity
        self.score = score
        self.days = days
    }

    public var id: Activity { activity }

    public var rating: SuitabilityRating { SuitabilityRating(score: score) }

    /// Highest-scoring day. On a tie the earlier day wins, because sooner is more certain.
    public var bestDay: DayAssessment? {
        var best: DayAssessment?
        for day in days where day.score > (best?.score ?? Int.min) {
            best = day
        }
        return best
    }
}

/// Everything the ranking screen needs for one place.
public struct ActivityReport: Equatable, Sendable {
    public let city: City
    public let timeZone: TimeZone
    public let days: [DailyForecast]
    /// Sorted best first.
    public let rankings: [ActivityRanking]

    public init(city: City, timeZone: TimeZone, days: [DailyForecast], rankings: [ActivityRanking]) {
        self.city = city
        self.timeZone = timeZone
        self.days = days
        self.rankings = rankings
    }
}
