import Testing
@testable import LocationActivitiesKit

// Expected numbers below were worked out by hand from the weights in each scorer.
// If you retune a scorer, these are the tests that should change, on purpose.

@Suite("Skiing")
struct SkiingScorerTests {
    private let scorer = SkiingScorer()
    private let powderDay = DailyForecast.make(
        condition: .snow, high: -4, low: -10, snowfall: 15, wind: 15, sunshineHours: 2
    )

    @Test("Fresh snow, cold and calm is close to ideal")
    func freshPowder() {
        let result = scorer.assess(powderDay)
        #expect(result.score == 94)
        #expect(result.summary == "15 cm fresh snow, high of -4°")
    }

    @Test("No snow and above freezing all day is capped near zero, whatever the sunshine")
    func warmDayIsCapped() {
        let result = scorer.assess(.make(high: 22, low: 12))
        #expect(result.score <= 10)
        #expect(result.summary.hasPrefix("Too warm"))
    }

    @Test("Strong wind costs points and is called out")
    func windyDay() {
        let result = scorer.assess(.make(
            condition: .snow, high: -4, low: -10, snowfall: 15, wind: 60, sunshineHours: 2
        ))
        #expect(result.score == 74)
        #expect(result.summary.contains("close lifts"))
    }
}

@Suite("Surfing")
struct SurfingScorerTests {
    private let scorer = SurfingScorer()

    @Test("Warm, light wind, dry and sunny scores full marks")
    func idealDay() {
        #expect(scorer.assess(.make(high: 26, wind: 10, sunshineHours: 9)).score == 100)
    }

    @Test("Thunderstorms are a safety cap, not a small penalty")
    func thunderstormIsCapped() {
        let result = scorer.assess(.make(condition: .thunderstorm, high: 26, wind: 10, sunshineHours: 9))
        #expect(result.score <= 5)
        #expect(result.summary.contains("stay out of the water"))
    }

    @Test("Strong wind means blown-out conditions")
    func blownOut() {
        let result = scorer.assess(.make(high: 26, wind: 45, sunshineHours: 9))
        #expect(result.score == 60)
        #expect(result.summary.hasPrefix("Blown out"))
    }
}

@Suite("Outdoor sightseeing")
struct OutdoorSightseeingScorerTests {
    private let scorer = OutdoorSightseeingScorer()

    @Test("A mild, dry, sunny day is perfect")
    func pleasantDay() {
        #expect(scorer.assess(.make()).score == 100)
    }

    @Test("A cold, wet, windy day scores poorly and mentions the rain chance")
    func rainyDay() {
        let result = scorer.assess(.make(
            condition: .rain, high: 9, precipitation: 12, precipitationProbability: 90, wind: 30
        ))
        #expect(result.score == 23)
        #expect(result.summary == "Rain, high of 9°, 90% chance of rain")
    }

    @Test("Thunderstorms cap the score")
    func thunderstorm() {
        #expect(scorer.assess(.make(condition: .thunderstorm)).score == 15)
    }

    @Test("Falls back to rainfall amount when probability is missing")
    func missingProbability() {
        #expect(scorer.assess(.make(precipitation: 4, precipitationProbability: nil)).score == 84)
    }
}

@Suite("Indoor sightseeing")
struct IndoorSightseeingScorerTests {
    private let indoor = IndoorSightseeingScorer()
    private let outdoor = OutdoorSightseeingScorer()

    @Test("Beats outdoor sightseeing on a miserable day")
    func winsWhenWeatherIsBad() {
        let rainy = DailyForecast.make(condition: .rain, high: 9, precipitation: 12, precipitationProbability: 90, wind: 30)
        #expect(indoor.assess(rainy).score == 81)
        #expect(indoor.assess(rainy).score > outdoor.assess(rainy).score)
    }

    @Test("Still viable, but loses to outdoor sightseeing on a lovely day")
    func losesWhenWeatherIsGood() {
        let lovely = DailyForecast.make()
        #expect(indoor.assess(lovely).score == 50)
        #expect(indoor.assess(lovely).score < outdoor.assess(lovely).score)
    }

    @Test("Storms make getting around harder, so indoor loses a little")
    func stormPenalty() {
        #expect(indoor.assess(.make(condition: .thunderstorm)).score == 74)
    }
}

@Suite("WeatherCondition")
struct WeatherConditionTests {
    @Test(
        "Maps WMO codes",
        arguments: zip(
            [0, 2, 3, 45, 53, 57, 63, 75, 81, 86, 99, 42],
            [WeatherCondition.clear, .partlyCloudy, .overcast, .fog, .drizzle, .freezingRain,
             .rain, .snow, .showers, .snowShowers, .thunderstorm, .unknown]
        )
    )
    func mapsCode(code: Int, expected: WeatherCondition) {
        #expect(WeatherCondition(wmoCode: code) == expected)
    }
}

@Suite("SuitabilityRating")
struct SuitabilityRatingTests {
    @Test(arguments: zip([100, 75, 74, 55, 54, 35, 34, 0],
                         [SuitabilityRating.excellent, .excellent, .good, .good, .fair, .fair, .poor, .poor]))
    func thresholds(score: Int, expected: SuitabilityRating) {
        #expect(SuitabilityRating(score: score) == expected)
    }
}
