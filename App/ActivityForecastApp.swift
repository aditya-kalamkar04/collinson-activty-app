import SwiftUI
import ActivityForecastKit

@main
struct ActivityForecastApp: App {
    private let container: AppContainer
    @State private var searchViewModel: CitySearchViewModel

    init() {
        let container = AppContainer.live()
        self.container = container
        _searchViewModel = State(initialValue: container.makeCitySearchViewModel())
    }

    var body: some Scene {
        WindowGroup {
            CitySearchView(viewModel: searchViewModel)
                .environment(\.appContainer, container)
        }
    }
}
