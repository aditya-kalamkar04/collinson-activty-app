import Foundation

public struct OpenMeteoForecastService: ForecastRepository {
    static let dailyVariables = [
        "weather_code",
        "temperature_2m_max",
        "temperature_2m_min",
        "precipitation_sum",
        "precipitation_probability_max",
        "snowfall_sum",
        "wind_speed_10m_max",
        "wind_gusts_10m_max",
        "sunshine_duration"
    ]

    private let client: APIClient
    private let forecastDays: Int

    public init(client: APIClient, forecastDays: Int = 7) {
        self.client = client
        self.forecastDays = forecastDays
    }

    public func forecast(for city: City) async throws -> Forecast {
        let endpoint = Endpoint(
            baseURL: OpenMeteoAPI.forecastBaseURL,
            path: OpenMeteoAPI.forecastPath,
            queryItems: [
                URLQueryItem(name: "latitude", value: String(city.latitude)),
                URLQueryItem(name: "longitude", value: String(city.longitude)),
                URLQueryItem(name: "daily", value: Self.dailyVariables.joined(separator: ",")),
                // Days should start and end at local midnight for the place, not the device.
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "forecast_days", value: String(forecastDays)),
                // These are the API defaults, pinned so a default change can't skew the scores.
                URLQueryItem(name: "temperature_unit", value: "celsius"),
                URLQueryItem(name: "wind_speed_unit", value: "kmh"),
                URLQueryItem(name: "precipitation_unit", value: "mm")
            ]
        )
        let response: ForecastResponseDTO = try await client.get(endpoint)
        return ForecastMapper.map(response)
    }
}
