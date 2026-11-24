@testable import LocationActivitiesKit

extension ViewState {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var emptyMessage: String? {
        if case .empty(let message) = self { return message }
        return nil
    }

    var failureMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}
