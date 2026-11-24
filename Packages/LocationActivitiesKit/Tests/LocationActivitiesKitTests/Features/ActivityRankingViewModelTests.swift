import Foundation
import Testing
@testable import LocationActivitiesKit

@MainActor
@Suite("ActivityRankingViewModel")
struct ActivityRankingViewModelTests {
    private let report = ActivityReport(city: .london, timeZone: .london, days: [], rankings: [])

    @Test("Loads the report once, even if the view reappears")
    func loadsOnce() async {
        let spy = RankActivitiesUseCaseSpy(result: .success(report))
        let sut = ActivityRankingViewModel(city: .london, rankActivities: spy)

        await sut.loadIfNeeded()
        await sut.loadIfNeeded()

        #expect(sut.state == .loaded(report))
        #expect(await spy.callCount == 1)
    }

    @Test("Shows a friendly message on failure")
    func failure() async {
        let spy = RankActivitiesUseCaseSpy(result: .failure(NetworkError.httpStatus(503)))
        let sut = ActivityRankingViewModel(city: .london, rankActivities: spy)

        await sut.loadIfNeeded()

        #expect(sut.state.failureMessage == UserFacingError.message(for: NetworkError.httpStatus(503)))
    }

    @Test("Reload always fetches again")
    func reload() async {
        let spy = RankActivitiesUseCaseSpy(result: .success(report))
        let sut = ActivityRankingViewModel(city: .london, rankActivities: spy)

        await sut.loadIfNeeded()
        await sut.reload()

        #expect(await spy.callCount == 2)
    }
}
