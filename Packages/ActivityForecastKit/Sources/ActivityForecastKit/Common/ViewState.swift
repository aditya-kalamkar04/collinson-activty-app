import Foundation

/// The five states every remote-data screen goes through. Shared by all features so each
/// screen renders loading, empty, and error the same way.
public enum ViewState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case empty(message: String)
    case failed(message: String)

    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

extension ViewState: Equatable where Value: Equatable {}
