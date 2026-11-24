import SwiftUI
import ActivityForecastKit

struct ActivityRankingView: View {
    @State private var viewModel: ActivityRankingViewModel

    init(viewModel: ActivityRankingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadableView(
            state: viewModel.state,
            loadingMessage: "Checking the forecast…",
            retry: retry
        ) { report in
            ActivityReportList(report: report)
                .refreshable { await viewModel.reload() }
        }
        .navigationTitle(viewModel.city.name)
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.loadIfNeeded() }
    }

    private func retry() {
        Task { await viewModel.reload() }
    }
}

private struct ActivityReportList: View {
    let report: ActivityReport

    private var dayLabels: DayLabelFormatter { DayLabelFormatter(timeZone: report.timeZone) }

    var body: some View {
        List {
            Section {
                ForEach(Array(report.rankings.enumerated()), id: \.element.id) { index, ranking in
                    ActivityRankingCard(rank: index + 1, ranking: ranking, dayLabels: dayLabels)
                }
            } header: {
                if !report.city.subtitle.isEmpty {
                    Text("\(report.city.subtitle) · next \(report.days.count) days")
                }
            } footer: {
                Text("Scores run from 0 to 100 and are worked out from the 7-day weather forecast. Surfing rates the weather only; wave data isn't included.")
            }
        }
        .listStyle(.insetGrouped)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ActivityRankingView(
            viewModel: AppContainer.preview.makeActivityRankingViewModel(for: PreviewData.london)
        )
    }
}
#endif
