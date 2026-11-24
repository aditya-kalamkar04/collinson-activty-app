import Foundation
import Testing
@testable import LocationActivitiesKit

@Suite("DayLabelFormatter")
struct DayLabelFormatterTests {
    private let posix = Locale(identifier: "en_US_POSIX")
    private let wednesday = DailyForecast.referenceDate // 2026-11-18 00:00 UTC

    @Test("Same calendar day is 'Today'")
    func today() {
        let sut = DayLabelFormatter(timeZone: .london, locale: posix)
        #expect(sut.shortLabel(for: wednesday, now: wednesday.addingTimeInterval(3 * 3600)) == "Today")
    }

    @Test("Other days use the abbreviated weekday")
    func weekday() {
        let sut = DayLabelFormatter(timeZone: .london, locale: posix)
        let thursday = wednesday.addingTimeInterval(86_400)
        #expect(sut.shortLabel(for: thursday, now: wednesday) == "Thu")
        #expect(sut.longLabel(for: thursday, now: wednesday).contains("Thursday"))
    }

    @Test("'Today' is judged in the destination's time zone, not the device's")
    func usesDestinationTimeZone() throws {
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        // 20:00 UTC on the 18th is still the 18th in London but already the 19th in Tokyo.
        let now = wednesday.addingTimeInterval(20 * 3600)

        #expect(DayLabelFormatter(timeZone: .london, locale: posix).shortLabel(for: wednesday, now: now) == "Today")
        #expect(DayLabelFormatter(timeZone: tokyo, locale: posix).shortLabel(for: wednesday, now: now) == "Wed")
    }
}

@Suite("UserFacingError")
struct UserFacingErrorTests {
    @Test func offline() {
        #expect(UserFacingError.message(for: NetworkError.offline).contains("offline"))
    }

    @Test func serverError() {
        #expect(UserFacingError.message(for: NetworkError.httpStatus(503)).contains("having problems"))
    }

    @Test func rateLimited() {
        #expect(UserFacingError.message(for: NetworkError.httpStatus(429)).contains("Too many requests"))
    }

    @Test func unknownError() {
        #expect(UserFacingError.message(for: StubError()) == "Something went wrong. Please try again.")
    }
}
