import Foundation

/// Turns one day of weather into a 0–100 suitability score for one activity.
///
/// Scorers are pure and synchronous: same input, same output, no I/O.
/// That keeps the most opinionated part of the app the easiest part to test and tune.
public protocol ActivityScoring: Sendable {
    var activity: Activity { get }
    func assess(_ day: DailyForecast) -> DayAssessment
}
