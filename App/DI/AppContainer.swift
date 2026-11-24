import Foundation
import SwiftUI
import ActivityForecastKit

/// Composition root: the one place that knows about concrete types.
///
/// Every screen gets its dependencies from here, so the forecast cache (an actor) is a
/// single shared instance. Going back to a city you just viewed is instant, and two
/// screens asking for the same city share one network call.
final class AppContainer: Sendable {
    let searchCitiesUseCase: any SearchCitiesUseCase
    let rankActivitiesUseCase: any RankActivitiesUseCase

    init(searchCitiesUseCase: any SearchCitiesUseCase, rankActivitiesUseCase: any RankActivitiesUseCase) {
        self.searchCitiesUseCase = searchCitiesUseCase
        self.rankActivitiesUseCase = rankActivitiesUseCase
    }

    static func live() -> AppContainer {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = 15

        let apiClient = APIClient(http: URLSessionHTTPClient(session: URLSession(configuration: configuration)))
        let cityRepository = OpenMeteoGeocodingService(client: apiClient)
        let forecastRepository = CachedForecastRepository(
            upstream: OpenMeteoForecastService(client: apiClient)
        )

        return AppContainer(
            searchCitiesUseCase: DefaultSearchCitiesUseCase(repository: cityRepository),
            rankActivitiesUseCase: DefaultRankActivitiesUseCase(forecasts: forecastRepository)
        )
    }

    @MainActor
    func makeCitySearchViewModel() -> CitySearchViewModel {
        CitySearchViewModel(searchCities: searchCitiesUseCase)
    }

    @MainActor
    func makeActivityRankingViewModel(for city: City) -> ActivityRankingViewModel {
        ActivityRankingViewModel(city: city, rankActivities: rankActivitiesUseCase)
    }
}

// MARK: - Environment

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue: AppContainer = .live()
}

extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
