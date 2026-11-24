import SwiftUI
import ActivityForecastKit

struct DayForecastRow: View {
    let day: DailyForecast
    let dayLabels: DayLabelFormatter

    var body: some View {
        HStack(spacing: 12) {
            Text(dayLabels.shortLabel(for: day.date))
                .frame(width: 52, alignment: .leading)

            Image(systemName: day.condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(day.condition.description)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(day.temperatureMax.formatted(.number.precision(.fractionLength(0))))° / \(day.temperatureMin.formatted(.number.precision(.fractionLength(0))))°")
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var detail: String {
        var parts = ["Wind \(day.windSpeedMax.formatted(.number.precision(.fractionLength(0)))) km/h"]
        if let probability = day.precipitationProbability {
            parts.append("Rain \(probability)%")
        }
        if day.snowfallSum >= 0.5 {
            parts.append("Snow \(day.snowfallSum.formatted(.number.precision(.fractionLength(0)))) cm")
        }
        return parts.joined(separator: " · ")
    }
}
