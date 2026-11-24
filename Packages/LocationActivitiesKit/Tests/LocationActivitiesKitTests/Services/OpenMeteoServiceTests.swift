import Foundation
import Testing
@testable import LocationActivitiesKit

@Suite("OpenMeteoGeocodingService")
struct OpenMeteoGeocodingServiceTests {
    @Test("Builds the documented search request")
    func buildsRequest() async throws {
        let http = MockHTTPClient(body: JSONFixtures.geocodingLondon)
        let sut = OpenMeteoGeocodingService(client: APIClient(http: http))

        _ = try await sut.cities(matching: "New York")

        let request = try #require(await http.requests.first)
        #expect(request.url?.host == "geocoding-api.open-meteo.com")
        #expect(request.url?.path == "/v1/search")
        #expect(request.httpMethod == "GET")
        let query = await http.lastQueryItems
        #expect(query["name"] == "New York")
        #expect(query["count"] == "10")
        #expect(query["language"] == "en")
        #expect(query["format"] == "json")
    }

    @Test("Maps results into cities, keeping region and country to tell them apart")
    func mapsResults() async throws {
        let sut = OpenMeteoGeocodingService(client: APIClient(http: MockHTTPClient(body: JSONFixtures.geocodingLondon)))

        let cities = try await sut.cities(matching: "London")

        #expect(cities.count == 2)
        let first = try #require(cities.first)
        #expect(first == .london)
        #expect(first.subtitle == "England, United Kingdom")
        #expect(cities[1].subtitle == "Ontario, Canada")
    }

    @Test("A missing results key means no matches, not a decoding error")
    func noResults() async throws {
        let sut = OpenMeteoGeocodingService(client: APIClient(http: MockHTTPClient(body: JSONFixtures.geocodingNoResults)))

        let cities = try await sut.cities(matching: "Qwxyz")

        #expect(cities.isEmpty)
    }

    @Test("Server errors surface as NetworkError.httpStatus")
    func serverError() async {
        let sut = OpenMeteoGeocodingService(client: APIClient(http: MockHTTPClient(statusCode: 500, body: "{}")))

        await #expect(throws: NetworkError.httpStatus(500)) {
            try await sut.cities(matching: "London")
        }
    }

    @Test("Malformed JSON surfaces as a decoding error")
    func malformedJSON() async {
        let sut = OpenMeteoGeocodingService(client: APIClient(http: MockHTTPClient(body: "{ not json")))

        do {
            _ = try await sut.cities(matching: "London")
            Issue.record("Expected a decoding error")
        } catch let error as NetworkError {
            guard case .decoding = error else {
                Issue.record("Expected .decoding, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error \(error)")
        }
    }
}

@Suite("OpenMeteoForecastService")
struct OpenMeteoForecastServiceTests {
    @Test("Requests 7 days of daily data in the location's own time zone and pinned units")
    func buildsRequest() async throws {
        let http = MockHTTPClient(body: JSONFixtures.forecastLondon)
        let sut = OpenMeteoForecastService(client: APIClient(http: http))

        _ = try await sut.forecast(for: .london)

        let request = try #require(await http.requests.first)
        #expect(request.url?.host == "api.open-meteo.com")
        #expect(request.url?.path == "/v1/forecast")
        let query = await http.lastQueryItems
        #expect(query["latitude"] == "51.50853")
        #expect(query["longitude"] == "-0.12574")
        #expect(query["timezone"] == "auto")
        #expect(query["forecast_days"] == "7")
        #expect(query["wind_speed_unit"] == "kmh")
        let daily = Set((query["daily"] ?? "").split(separator: ",").map(String.init))
        #expect(daily == Set(OpenMeteoForecastService.dailyVariables))
    }

    @Test("Maps the parallel daily arrays into one value per day")
    func mapsDays() async throws {
        let sut = OpenMeteoForecastService(client: APIClient(http: MockHTTPClient(body: JSONFixtures.forecastLondon)))

        let forecast = try await sut.forecast(for: .london)

        #expect(forecast.timeZone == .london)
        #expect(forecast.days.count == 7)

        let first = try #require(forecast.days.first)
        #expect(first.date == DailyForecast.referenceDate)
        #expect(first.condition == .overcast)
        #expect(first.temperatureMax == 11.2)
        #expect(first.temperatureMin == 6.1)
        #expect(first.precipitationProbability == 10)
        #expect(first.sunshineDuration == 7200)

        let snowy = forecast.days[5]
        #expect(snowy.condition == .snow)
        #expect(snowy.snowfallSum == 3.5)
        #expect(forecast.days[6].condition == .thunderstorm)
    }

    @Test("Drops days missing core values and defaults missing secondary values")
    func handlesNulls() async throws {
        let sut = OpenMeteoForecastService(client: APIClient(http: MockHTTPClient(body: JSONFixtures.forecastWithNulls)))

        let forecast = try await sut.forecast(for: .london)

        #expect(forecast.days.count == 2)
        let last = try #require(forecast.days.last)
        #expect(last.temperatureMax == 12)
        #expect(last.windSpeedMax == 0)
        #expect(last.precipitationProbability == nil)
    }
}

@Suite("APIClient error mapping")
struct APIClientTests {
    private let endpoint = Endpoint(baseURL: URL(string: "https://example.com")!, path: "v1/thing")

    private struct Empty: Decodable, Sendable {}

    @Test("No connection becomes .offline")
    func offline() async {
        let sut = APIClient(http: MockHTTPClient(error: URLError(.notConnectedToInternet)))
        await #expect(throws: NetworkError.offline) {
            try await sut.get(endpoint, as: Empty.self)
        }
    }

    @Test("Time-outs become .timedOut")
    func timedOut() async {
        let sut = APIClient(http: MockHTTPClient(error: URLError(.timedOut)))
        await #expect(throws: NetworkError.timedOut) {
            try await sut.get(endpoint, as: Empty.self)
        }
    }

    @Test("A cancelled URL task becomes CancellationError so the UI can ignore it")
    func cancelled() async {
        let sut = APIClient(http: MockHTTPClient(error: URLError(.cancelled)))
        await #expect(throws: CancellationError.self) {
            try await sut.get(endpoint, as: Empty.self)
        }
    }
}
