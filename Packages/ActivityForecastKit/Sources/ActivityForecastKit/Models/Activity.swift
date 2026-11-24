import Foundation

public enum Activity: String, CaseIterable, Identifiable, Sendable {
    case skiing
    case surfing
    case outdoorSightseeing
    case indoorSightseeing

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .skiing: "Skiing"
        case .surfing: "Surfing"
        case .outdoorSightseeing: "Outdoor sightseeing"
        case .indoorSightseeing: "Indoor sightseeing"
        }
    }

    /// Stable order used to break ties between equally scored activities.
    var sortIndex: Int {
        Activity.allCases.firstIndex(of: self) ?? 0
    }
}
