import Foundation
import Observation

@MainActor
@Observable
public final class ActivityRankingViewModel {
    public let city: City
    public private(set) var state: ViewState<ActivityReport> = .idle

    @ObservationIgnored private let rankActivities: any RankActivitiesUseCase
    @ObservationIgnored private var isRequestInFlight = false

    public init(city: City, rankActivities: any RankActivitiesUseCase) {
        self.city = city
        self.rankActivities = rankActivities
    }

    /// Safe to call from `.task`, which re-runs whenever the view reappears.
    public func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    /// Retry after an error, or pull-to-refresh. Existing content stays on screen while
    /// refreshing instead of flashing a spinner.
    public func reload() async {
        await load()
    }

    private func load() async {
        guard !isRequestInFlight else { return }
        isRequestInFlight = true
        defer { isRequestInFlight = false }

        if state.value == nil {
            state = .loading
        }

        do {
            let report = try await rankActivities.execute(for: city)
            state = .loaded(report)
        } catch is CancellationError {
            // The view went away mid-request. Go back to idle so the next appearance retries.
            if state.isLoading { state = .idle }
        } catch {
            state = .failed(message: UserFacingError.message(for: error))
        }
    }
}
