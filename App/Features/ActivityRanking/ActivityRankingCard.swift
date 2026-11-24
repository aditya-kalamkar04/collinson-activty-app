import SwiftUI
import ActivityForecastKit

struct ActivityRankingCard: View {
    let rank: Int
    let ranking: ActivityRanking
    let dayLabels: DayLabelFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: ranking.activity.symbolName)
                    .font(.title2)
                    .foregroundStyle(ranking.activity.tint)
                    .frame(width: 36)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(rank). \(ranking.activity.displayName)")
                        .font(.headline)
                    if let best = ranking.bestDay {
                        Text("Best: \(dayLabels.shortLabel(for: best.date)) · \(best.summary)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                ScoreBadge(score: ranking.score)
            }

            ScoreBarsView(
                days: ranking.days,
                dayLabels: dayLabels,
                tint: ranking.activity.tint,
                highlightedDate: ranking.bestDay?.date
            )
        }
        .padding(.vertical, 6)
    }
}
