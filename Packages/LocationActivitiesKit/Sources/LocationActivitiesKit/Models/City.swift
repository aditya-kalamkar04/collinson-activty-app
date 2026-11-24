import Foundation

/// A place returned by geocoding. Identity comes from Open-Meteo's stable location id.
public struct City: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    /// First-level administrative area (state, county, region).
    public let region: String?
    public let country: String?
    public let countryCode: String?
    public let latitude: Double
    public let longitude: Double
    /// Metres above sea level, when known.
    public let elevation: Double?
    public let timeZoneIdentifier: String?

    public init(
        id: Int,
        name: String,
        region: String? = nil,
        country: String? = nil,
        countryCode: String? = nil,
        latitude: Double,
        longitude: Double,
        elevation: Double? = nil,
        timeZoneIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.region = region
        self.country = country
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    /// "Maharashtra, India" — used to tell apart places that share a name.
    public var subtitle: String {
        [region, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
