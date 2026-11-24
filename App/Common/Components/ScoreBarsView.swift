import SwiftUI
import ActivityForecastKit

/// Seven small bars, one per day: shows the shape of the week at a glance.
struct ScoreBarsView: View {
    let days: [DayAssessment]
    let dayLabels: DayLabelFormatter
    let tint: Color
    var highlightedDate: Date?

    private let maxBarHeight: CGFloat = 44

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(days, id: \.date) { day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(tint.opacity(day.date == highlightedDate ? 1 : 0.45))
                        .frame(height: max(4, maxBarHeight * CGFloat(day.score) / 100))
                        .frame(height: maxBarHeight, alignment: .bottom)
                    Text(dayLabels.shortLabel(for: day.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(dayLabels.longLabel(for: day.date)), score \(day.score). \(day.summary)")
            }
        }
    }
}
