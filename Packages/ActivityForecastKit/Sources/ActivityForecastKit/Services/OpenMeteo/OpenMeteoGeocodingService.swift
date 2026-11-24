import Foundation

public struct OpenMeteoGeocodingService: CityRepository {
    private let client: APIClient
    private let resultLimit: Int
    private let language: String

    public init(client: APIClient, resultLimit: Int = 10, language: String = "en") {
        self.client = client
        self.resultLimit = resultLimit
        self.language = language
    }

    public func cities(matching query: String) async throws -> [City] {
        let endpoint = Endpoint(
            baseURL: OpenMeteoAPI.geocodingBaseURL,
            path: OpenMeteoAPI.geocodingPath,
            queryItems: [
                URLQueryItem(name: "name", value: query),
                URLQueryItem(name: "count", value: String(resultLimit)),
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "format", value: "json")
            ]
        )
        let response: GeocodingResponseDTO = try await client.get(endpoint)
        return (response.results ?? []).map(City.init(dto:))
    }
}
