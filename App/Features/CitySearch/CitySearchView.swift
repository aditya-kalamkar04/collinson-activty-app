import SwiftUI
import ActivityForecastKit

struct CitySearchView: View {
    @Environment(\.appContainer) private var container
    @State private var viewModel: CitySearchViewModel

    init(viewModel: CitySearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            LoadableView(
                state: viewModel.state,
                loadingMessage: "Searching…",
                emptyTitle: "No places found",
                retry: { viewModel.retry() }
            ) {
                ContentUnavailableView(
                    "Where are you headed?",
                    systemImage: "mappin.and.ellipse",
                    description: Text("Search for a city or town to see how the next 7 days look for skiing, surfing and sightseeing.")
                )
            } content: { cities in
                List(cities) { city in
                    NavigationLink(value: city) {
                        CityRow(city: city)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Activity Forecast")
            .searchable(
                text: Binding(get: { viewModel.query }, set: { viewModel.updateQuery($0) }),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "City or town"
            )
            .autocorrectionDisabled()
            .navigationDestination(for: City.self) { city in
                ActivityRankingView(viewModel: container.makeActivityRankingViewModel(for: city))
            }
        }
    }
}

private struct CityRow: View {
    let city: City

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(city.name)
                .font(.body.weight(.medium))
            if !city.subtitle.isEmpty {
                Text(city.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    CitySearchView(viewModel: AppContainer.preview.makeCitySearchViewModel())
        .environment(\.appContainer, .preview)
}
#endif
