import Foundation

/// Simplified view of the WMO weather interpretation codes Open-Meteo returns.
/// https://open-meteo.com/en/docs (see "WMO Weather interpretation codes")
public enum WeatherCondition: Sendable, Equatable, CaseIterable {
    case clear
    case partlyCloudy
    case overcast
    case fog
    case drizzle
    case rain
    case freezingRain
    case snow
    case showers
    case snowShowers
    case thunderstorm
    case unknown

    public init(wmoCode: Int) {
        switch wmoCode {
        case 0: self = .clear
        case 1, 2: self = .partlyCloudy
        case 3: self = .overcast
        case 45, 48: self = .fog
        case 51, 53, 55: self = .drizzle
        case 56, 57, 66, 67: self = .freezingRain
        case 61, 63, 65: self = .rain
        case 71, 73, 75, 77: self = .snow
        case 80, 81, 82: self = .showers
        case 85, 86: self = .snowShowers
        case 95, 96, 99: self = .thunderstorm
        default: self = .unknown
        }
    }

    public var description: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly cloudy"
        case .overcast: "Overcast"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .freezingRain: "Freezing rain"
        case .snow: "Snow"
        case .showers: "Showers"
        case .snowShowers: "Snow showers"
        case .thunderstorm: "Thunderstorms"
        case .unknown: "Mixed"
        }
    }
}
