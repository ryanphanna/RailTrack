import Foundation

extension Date {
    /// "3:42 PM"
    var timeString: String {
        formatted(date: .omitted, time: .shortened)
    }

    /// "Mon, May 27"
    var shortDateString: String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// "Today", "Tomorrow", or "May 27"
    var relativeDayString: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) { return "Today" }
        if cal.isDateInTomorrow(self) { return "Tomorrow" }
        return formatted(.dateTime.month(.abbreviated).day())
    }

    /// Minutes from now (positive = future)
    var minutesFromNow: Int {
        Int(timeIntervalSinceNow / 60)
    }
}

extension Int {
    /// 127 → "2h 7m"
    var durationString: String {
        let h = self / 60
        let m = self % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
