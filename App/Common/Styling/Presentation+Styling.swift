import SwiftUI
import ActivityForecastKit

// Presentation-only mapping (SF Symbols, colours) lives in the app target, so the
// domain package stays free of SwiftUI.

extension Activity {
    var symbolName: String {
        switch self {
        case .skiing: "figure.skiing.downhill"
        case .surfing: "figure.surfing"
        case .outdoorSightseeing: "binoculars.fill"
        case .indoorSightseeing: "building.columns.fill"
        }
    }

    var tint: Color {
        switch self {
        case .skiing: .cyan
        case .surfing: .blue
        case .outdoorSightseeing: .green
        case .indoorSightseeing: .purple
        }
    }
}

extension SuitabilityRating {
    var tint: Color {
        switch self {
        case .excellent: .green
        case .good: .teal
        case .fair: .orange
        case .poor: .red
        }
    }
}

extension WeatherCondition {
    var symbolName: String {
        switch self {
        case .clear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .overcast: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .freezingRain: "cloud.sleet.fill"
        case .snow, .snowShowers: "cloud.snow.fill"
        case .showers: "cloud.heavyrain.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .unknown: "questionmark.circle"
        }
    }
}
