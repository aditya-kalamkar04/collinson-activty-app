import Foundation

public enum CitySearchPolicy {
    /// Open-Meteo returns nothing useful for a single character, so we don't ask.
    public static let minimumQueryLength = 2
}

public protocol SearchCitiesUseCase: Sendable {
    func execute(query: String) async throws -> [City]
}

public struct DefaultSearchCitiesUseCase: SearchCitiesUseCase {
    private let repository: any CityRepository

    public init(repository: any CityRepository) {
        self.repository = repository
    }

    public func execute(query: String) async throws -> [City] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= CitySearchPolicy.minimumQueryLength else { return [] }
        return try await repository.cities(matching: trimmed)
    }
}
