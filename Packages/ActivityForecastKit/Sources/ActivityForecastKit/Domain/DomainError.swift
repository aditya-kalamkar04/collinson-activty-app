import Foundation

public enum DomainError: Error, Equatable, Sendable {
    /// The provider answered, but with no usable days for this location.
    case noForecastAvailable
}
