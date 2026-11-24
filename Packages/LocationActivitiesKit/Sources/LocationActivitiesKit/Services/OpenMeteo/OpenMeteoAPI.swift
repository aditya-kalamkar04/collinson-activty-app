import Foundation

/// Open-Meteo needs no API key, so there is no secret to manage here.
enum OpenMeteoAPI {
    static let geocodingBaseURL = URL(string: "https://geocoding-api.open-meteo.com")!
    static let forecastBaseURL = URL(string: "https://api.open-meteo.com")!

    static let geocodingPath = "v1/search"
    static let forecastPath = "v1/forecast"
}
