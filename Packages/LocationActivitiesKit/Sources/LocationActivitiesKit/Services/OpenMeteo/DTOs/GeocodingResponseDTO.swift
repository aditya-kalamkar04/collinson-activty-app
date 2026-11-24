import Foundation

/// Mirrors https://geocoding-api.open-meteo.com/v1/search
/// Note: `results` is omitted entirely, not empty, when nothing matches.
struct GeocodingResponseDTO: Decodable, Sendable {
    let results: [Location]?

    struct Location: Decodable, Sendable {
        let id: Int
        let name: String
        let latitude: Double
        let longitude: Double
        let elevation: Double?
        let countryCode: String?
        let country: String?
        let admin1: String?
        let timezone: String?

        enum CodingKeys: String, CodingKey {
            case id, name, latitude, longitude, elevation, country, admin1, timezone
            case countryCode = "country_code"
        }
    }
}

extension City {
    init(dto: GeocodingResponseDTO.Location) {
        self.init(
            id: dto.id,
            name: dto.name,
            region: dto.admin1,
            country: dto.country,
            countryCode: dto.countryCode,
            latitude: dto.latitude,
            longitude: dto.longitude,
            elevation: dto.elevation,
            timeZoneIdentifier: dto.timezone
        )
    }
}
