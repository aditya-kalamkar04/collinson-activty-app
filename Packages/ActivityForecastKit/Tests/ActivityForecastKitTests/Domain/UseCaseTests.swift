import Foundation
import Testing
@testable import ActivityForecastKit

/// Scores each day by its high temperature, so tests can dictate scores precisely.
private struct TemperatureEchoScorer: ActivityScoring {
    let activity: Activity
    func assess(_ day: DailyForecast) -> DayAssessment {
        DayAssessment(date: day.date, score: Int(day.temperatureMax), summary: "")
    }
}

@Suite("RankActivitiesUseCase")
struct RankActivitiesUseCaseTests {
    @Test("Ranks the real scorers best first for a mild, dry week")
    func ranksStandardScorers() async throws {
        let repository = ForecastRepositorySpy(result: .success(.week()))
        let sut = DefaultRankActivitiesUseCase(forecasts: repository)

        let report = try await sut.execute(for: .london)

        #expect(report.rankings.map(\.activity) == [.outdoorSightseeing, .surfing, .indoorSightseeing, .skiing])
        #expect(report.rankings.map(\.score) == [100, 94, 50, 10])
        #expect(report.days.count == 7)
        #expect(report.timeZone == .london)
    }

    @Test("Weekly score is the rounded mean of the daily scores")
    func weeklyScoreIsMean() async throws {
        let days = [10.0, 20, 31].enumerated().map { offset, high in
            DailyForecast.make(dayOffset: offset, high: high)
        }
        let repository = ForecastRepositorySpy(result: .success(Forecast(timeZone: .london, days: days)))
        let sut = DefaultRankActivitiesUseCase(
            forecasts: repository,
            scorers: [TemperatureEchoScorer(activity: .skiing)]
        )

        let report = try await sut.execute(for: .london)

        #expect(report.rankings.first?.score == 20)
        #expect(report.rankings.first?.bestDay?.score == 31)
    }

    @Test("Ties are broken by the fixed activity order")
    func tieBreak() async throws {
        let repository = ForecastRepositorySpy(result: .success(.week()))
        let sut = DefaultRankActivitiesUseCase(
            forecasts: repository,
            scorers: [TemperatureEchoScorer(activity: .surfing), TemperatureEchoScorer(activity: .skiing)]
        )

        let report = try await sut.execute(for: .london)

        #expect(report.rankings.map(\.activity) == [.skiing, .surfing])
    }

    @Test("An empty forecast is an explicit error, not an empty screen")
    func emptyForecast() async {
        let repository = ForecastRepositorySpy(result: .success(Forecast(timeZone: .london, days: [])))
        let sut = DefaultRankActivitiesUseCase(forecasts: repository)

        await #expect(throws: DomainError.noForecastAvailable) {
            try await sut.execute(for: .london)
        }
    }

    @Test("Repository errors pass through untouched")
    func propagatesErrors() async {
        let repository = ForecastRepositorySpy(result: .failure(NetworkError.offline))
        let sut = DefaultRankActivitiesUseCase(forecasts: repository)

        await #expect(throws: NetworkError.offline) {
            try await sut.execute(for: .london)
        }
    }
}

@Suite("ActivityRanking")
struct ActivityRankingTests {
    @Test("Best day prefers the earlier day on a tie")
    func bestDayTieBreak() {
        let days = [50, 80, 80].enumerated().map { offset, score in
            DayAssessment(date: DailyForecast.make(dayOffset: offset).date, score: score, summary: "")
        }
        let ranking = ActivityRanking(activity: .skiing, score: 70, days: days)

        #expect(ranking.bestDay?.date == days[1].date)
    }
}

@Suite("SearchCitiesUseCase")
struct SearchCitiesUseCaseTests {
    @Test("Too-short queries never reach the network")
    func shortQuery() async throws {
        let repository = CityRepositorySpy(result: .success([.london]))
        let sut = DefaultSearchCitiesUseCase(repository: repository)

        let result = try await sut.execute(query: "  L ")

        #expect(result.isEmpty)
        #expect(await repository.receivedQueries.isEmpty)
    }

    @Test("Queries are trimmed before searching")
    func trimsQuery() async throws {
        let repository = CityRepositorySpy(result: .success([.london]))
        let sut = DefaultSearchCitiesUseCase(repository: repository)

        let result = try await sut.execute(query: "  London \n")

        #expect(result == [.london])
        #expect(await repository.receivedQueries == ["London"])
    }
}
