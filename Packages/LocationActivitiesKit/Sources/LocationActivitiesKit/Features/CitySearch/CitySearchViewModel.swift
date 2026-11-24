import Foundation
import Observation

/// Drives the search screen: debounces typing, cancels stale searches, and exposes one
/// `ViewState` for the view to render.
@MainActor
@Observable
public final class CitySearchViewModel {
    public private(set) var query = ""
    public private(set) var state: ViewState<[City]> = .idle

    @ObservationIgnored private let searchCities: any SearchCitiesUseCase
    @ObservationIgnored private let debounce: Duration
    /// Internal so tests can await the search they triggered.
    @ObservationIgnored private(set) var searchTask: Task<Void, Never>?

    public init(searchCities: any SearchCitiesUseCase, debounce: Duration = .milliseconds(350)) {
        self.searchCities = searchCities
        self.debounce = debounce
    }

    /// Called on every keystroke. Only the last query typed within the debounce window hits
    /// the network, and a slower earlier response can never overwrite a newer one.
    public func updateQuery(_ newValue: String) {
        guard newValue != query else { return }
        query = newValue
        scheduleSearch(delay: debounce)
    }

    public func retry() {
        scheduleSearch(delay: .zero)
    }

    private func scheduleSearch(delay: Duration) {
        searchTask?.cancel()

        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= CitySearchPolicy.minimumQueryLength else {
            searchTask = nil
            state = .idle
            return
        }

        state = .loading
        searchTask = Task { [weak self] in
            if delay > .zero {
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    return // Cancelled by a newer keystroke.
                }
            }
            await self?.search(term)
        }
    }

    private func search(_ term: String) async {
        do {
            let cities = try await searchCities.execute(query: term)
            guard !Task.isCancelled else { return }
            state = cities.isEmpty
                ? .empty(message: "No places match “\(term)”. Check the spelling or try a larger town nearby.")
                : .loaded(cities)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(message: UserFacingError.message(for: error))
        }
    }
}
