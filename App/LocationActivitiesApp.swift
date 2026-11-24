import SwiftUI
import LocationActivitiesKit

@main
struct LocationActivitiesApp: App {
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
