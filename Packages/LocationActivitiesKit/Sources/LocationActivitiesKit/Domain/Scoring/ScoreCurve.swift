import Foundation

/// Shared maths for the scorers: convert a raw value into a 0...1 "goodness" factor,
/// then blend factors with weights into a 0–100 score.
enum ScoreCurve {
    struct Factor: Sendable {
        let value: Double
        let weight: Double
    }

    /// Linear ramp that is 0 at `zeroAt` and 1 at `oneAt`, clamped outside that range.
    /// Works in either direction, so "less wind is better" is `ramp(wind, zeroAt: 50, oneAt: 20)`.
    static func ramp(_ value: Double, zeroAt: Double, oneAt: Double) -> Double {
        guard zeroAt != oneAt else { return value >= oneAt ? 1 : 0 }
        let progress = (value - zeroAt) / (oneAt - zeroAt)
        return min(max(progress, 0), 1)
    }

    /// 1 inside `ideal`, falling linearly to 0 once `tolerance` outside either edge.
    static func band(_ value: Double, ideal: ClosedRange<Double>, tolerance: Double) -> Double {
        if ideal.contains(value) { return 1 }
        guard tolerance > 0 else { return 0 }
        let distance = value < ideal.lowerBound
            ? ideal.lowerBound - value
            : value - ideal.upperBound
        return max(0, 1 - distance / tolerance)
    }

    static func weightedScore(_ factors: [Factor]) -> Int {
        let totalWeight = factors.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        let weighted = factors.reduce(0.0) { $0 + $1.value * $1.weight }
        return clamp(Int((weighted / totalWeight * 100).rounded()))
    }

    static func clamp(_ score: Int) -> Int {
        min(max(score, 0), 100)
    }
}

extension Double {
    /// Whole-number string for UI summaries, e.g. 12.6 -> "13", -0.3 -> "0".
    var wholeNumber: String {
        String(Int(self.rounded()))
    }
}
