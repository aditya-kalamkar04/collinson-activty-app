import Foundation

/// Turns technical errors into copy a user can act on. Kept out of the views so the
/// wording is tested and consistent across screens.
public enum UserFacingError {
    public static func message(for error: any Error) -> String {
        if let networkError = error as? NetworkError {
            return message(for: networkError)
        }
        if let domainError = error as? DomainError {
            switch domainError {
            case .noForecastAvailable:
                return "There's no forecast for this place right now. Try a nearby town."
            }
        }
        return "Something went wrong. Please try again."
    }

    private static func message(for error: NetworkError) -> String {
        switch error {
        case .offline:
            return "You seem to be offline. Check your connection and try again."
        case .timedOut:
            return "The weather service is taking too long to respond. Please try again."
        case .httpStatus(429):
            return "Too many requests in a short time. Wait a moment and try again."
        case .httpStatus(let code) where (500...599).contains(code):
            return "The weather service is having problems. Please try again shortly."
        case .invalidURL, .invalidResponse, .httpStatus, .decoding, .transport:
            return "We couldn't get the weather right now. Please try again."
        }
    }
}
