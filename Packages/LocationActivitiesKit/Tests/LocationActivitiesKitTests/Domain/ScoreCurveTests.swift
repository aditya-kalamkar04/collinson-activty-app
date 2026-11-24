import Testing
@testable import LocationActivitiesKit

@Suite("ScoreCurve")
struct ScoreCurveTests {
    @Test("Rising ramp interpolates and clamps")
    func risingRamp() {
        #expect(ScoreCurve.ramp(5, zeroAt: 0, oneAt: 10) == 0.5)
        #expect(ScoreCurve.ramp(-5, zeroAt: 0, oneAt: 10) == 0)
        #expect(ScoreCurve.ramp(15, zeroAt: 0, oneAt: 10) == 1)
    }

    @Test("Falling ramp treats lower values as better")
    func fallingRamp() {
        #expect(ScoreCurve.ramp(35, zeroAt: 50, oneAt: 20) == 0.5)
        #expect(ScoreCurve.ramp(10, zeroAt: 50, oneAt: 20) == 1)
        #expect(ScoreCurve.ramp(60, zeroAt: 50, oneAt: 20) == 0)
    }

    @Test("Degenerate ramp doesn't divide by zero")
    func degenerateRamp() {
        #expect(ScoreCurve.ramp(5, zeroAt: 5, oneAt: 5) == 1)
        #expect(ScoreCurve.ramp(4, zeroAt: 5, oneAt: 5) == 0)
    }

    @Test("Band is flat inside the ideal range and falls off outside it")
    func band() {
        #expect(ScoreCurve.band(20, ideal: 16...26, tolerance: 12) == 1)
        #expect(ScoreCurve.band(10, ideal: 16...26, tolerance: 12) == 0.5)
        #expect(ScoreCurve.band(32, ideal: 16...26, tolerance: 12) == 0.5)
        #expect(ScoreCurve.band(40, ideal: 16...26, tolerance: 12) == 0)
    }

    @Test("Weighted score respects weights and handles no factors")
    func weightedScore() {
        #expect(ScoreCurve.weightedScore([.init(value: 1, weight: 1), .init(value: 0, weight: 1)]) == 50)
        #expect(ScoreCurve.weightedScore([.init(value: 1, weight: 3), .init(value: 0, weight: 1)]) == 75)
        #expect(ScoreCurve.weightedScore([]) == 0)
    }
}
