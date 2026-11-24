import SwiftUI
import ActivityForecastKit

/// "72 · Good" capsule, coloured by rating. Colour is never the only signal: the word
/// is always shown too, for colour-blind users.
struct ScoreBadge: View {
    let score: Int

    private var rating: SuitabilityRating { SuitabilityRating(score: score) }

    var body: some View {
        HStack(spacing: 4) {
            Text("\(score)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
            Text(rating.title)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .foregroundStyle(rating.tint)
        .background(rating.tint.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Score \(score) out of 100, \(rating.title)")
    }
}

#Preview {
    VStack(spacing: 12) {
        ScoreBadge(score: 88)
        ScoreBadge(score: 63)
        ScoreBadge(score: 41)
        ScoreBadge(score: 12)
    }
}
