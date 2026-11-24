import Foundation
import Testing
@testable import LocationActivitiesKit

@MainActor
@Suite("CitySearchViewModel")
struct CitySearchViewModelTests {
    @Test("Starts idle")
    func initialState() {
        let sut = CitySearchViewModel(searchCities: SearchCitiesUseCaseSpy(result: .success([])))
        #expect(sut.state.isIdle)
        #expect(sut.query.isEmpty)
    }

    @Test("A one-letter query stays idle and doesn't search")
    func shortQuery() async {
        let spy = SearchCitiesUseCaseSpy(result: .success([.london]))
        let sut = CitySearchViewModel(searchCities: spy, debounce: .zero)

        sut.updateQuery("L")
        await sut.searchTask?.value

        #expect(sut.state.isIdle)
        #expect(await spy.receivedQueries.isEmpty)
    }

    @Test("Shows results when the search succeeds")
    func loaded() async {
        let sut = CitySearchViewModel(searchCities: SearchCitiesUseCaseSpy(result: .success([.london])), debounce: .zero)

        sut.updateQuery("London")
        #expect(sut.state.isLoading)
        await sut.searchTask?.value

        #expect(sut.state == .loaded([.london]))
    }

    @Test("Shows an empty state that repeats the query back")
    func empty() async {
        let sut = CitySearchViewModel(searchCities: SearchCitiesUseCaseSpy(result: .success([])), debounce: .zero)

        sut.updateQuery("Qwxyz")
        await sut.searchTask?.value

        #expect(sut.state.emptyMessage?.contains("Qwxyz") == true)
    }

    @Test("Shows a friendly error and can retry")
    func failureAndRetry() async {
        let spy = SearchCitiesUseCaseSpy(result: .failure(NetworkError.offline))
        let sut = CitySearchViewModel(searchCities: spy, debounce: .zero)

        sut.updateQuery("London")
        await sut.searchTask?.value
        #expect(sut.state.failureMessage == UserFacingError.message(for: NetworkError.offline))

        sut.retry()
        await sut.searchTask?.value
        #expect(await spy.receivedQueries == ["London", "London"])
    }

    @Test("Fast typing only searches for the last query")
    func debouncesTyping() async {
        let spy = SearchCitiesUseCaseSpy(result: .success([.london]))
        let sut = CitySearchViewModel(searchCities: spy, debounce: .milliseconds(100))

        sut.updateQuery("Lo")
        sut.updateQuery("Lon")
        sut.updateQuery("London")
        await sut.searchTask?.value

        #expect(await spy.receivedQueries == ["London"])
        #expect(sut.state == .loaded([.london]))
    }

    @Test("Clearing the field goes back to idle")
    func clearing() async {
        let sut = CitySearchViewModel(searchCities: SearchCitiesUseCaseSpy(result: .success([.london])), debounce: .zero)

        sut.updateQuery("London")
        await sut.searchTask?.value
        sut.updateQuery("")

        #expect(sut.state.isIdle)
    }
}
