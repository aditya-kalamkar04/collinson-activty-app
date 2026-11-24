import Foundation

/// Formats forecast dates in the *destination's* time zone. If you're in Pune looking at
/// Honolulu, "Today" has to mean today in Honolulu.
public struct DayLabelFormatter: Sendable {
    private let calendar: Calendar
    private let shortStyle: Date.FormatStyle
    private let longStyle: Date.FormatStyle

    public init(timeZone: TimeZone, locale: Locale = .autoupdatingCurrent) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = locale
        self.calendar = calendar

        let base = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: timeZone)
        self.shortStyle = base.weekday(.abbreviated)
        self.longStyle = base.weekday(.wide).day().month(.abbreviated)
    }

    /// "Today", otherwise "Wed".
    public func shortLabel(for date: Date, now: Date = .now) -> String {
        calendar.isDate(date, inSameDayAs: now) ? "Today" : date.formatted(shortStyle)
    }

    /// "Today", otherwise "Wednesday, 18 Nov" (order depends on locale).
    public func longLabel(for date: Date, now: Date = .now) -> String {
        calendar.isDate(date, inSameDayAs: now) ? "Today" : date.formatted(longStyle)
    }
}
