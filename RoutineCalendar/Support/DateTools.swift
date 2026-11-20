import Foundation

enum DateTools {
    static let locale = Locale(identifier: "ko_KR")

    static var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = locale
        return cal
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = format
        return f
    }

    private static let hmFormatter = formatter("HH:mm")
    private static let monthFormatter = formatter("yyyy년 M월")
    private static let dayFormatter = formatter("M월 d일 (E)")
    private static let shortDayFormatter = formatter("M/d")

    static func hm(_ date: Date) -> String { hmFormatter.string(from: date) }
    static func month(_ date: Date) -> String { monthFormatter.string(from: date) }
    static func day(_ date: Date) -> String { dayFormatter.string(from: date) }
    static func shortDay(_ date: Date) -> String { shortDayFormatter.string(from: date) }

    static func hm(minutes: Int) -> String {
        let m = ((minutes % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    static func startOfMonth(_ date: Date) -> Date {
        let cal = calendar
        return cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? cal.startOfDay(for: date)
    }

    static func addDays(_ n: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: n, to: date) ?? date
    }

    static func addMonths(_ n: Int, to date: Date) -> Date {
        calendar.date(byAdding: .month, value: n, to: date) ?? date
    }

    /// 날짜 + (자정부터의 분) 범위. 종료가 시작보다 빠르면 다음 날로 넘긴다.
    static func range(on day: Date, startMinute: Int, endMinute: Int) -> (start: Date, end: Date) {
        let cal = calendar
        let base = cal.startOfDay(for: day)
        let start = cal.date(byAdding: .minute, value: startMinute, to: base) ?? base
        var end = cal.date(byAdding: .minute, value: endMinute, to: base) ?? start
        if end <= start { end = cal.date(byAdding: .day, value: 1, to: end) ?? end }
        return (start, end)
    }

    /// Date의 시:분을 자정부터의 분으로.
    static func minutes(of date: Date) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// 오늘 날짜 기준으로 분을 Date로 (시간 선택기용).
    static func dateForMinutes(_ minutes: Int) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: calendar.startOfDay(for: Date())) ?? Date()
    }

    /// 시간을 직접 고를 때 처음 보여줄 시간대: 오늘이면 다음 정각, 아니면 10:00. 1시간짜리.
    static func suggestedRange(on day: Date) -> (start: Date, end: Date) {
        let cal = calendar
        var startMinute = 10 * 60
        if cal.isDateInToday(day) {
            let hour = cal.component(.hour, from: Date())
            startMinute = min(hour + 1, 23) * 60
        }
        return range(on: day, startMinute: startMinute, endMinute: startMinute + 60)
    }

    /// 월 달력에 그릴 날짜들 (앞뒤 달 날짜 포함, 7의 배수).
    static func monthGrid(for month: Date) -> [Date] {
        let cal = calendar
        let first = startOfMonth(month)
        let weekday = cal.component(.weekday, from: first)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        let daysInMonth = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let cells = Int((Double(offset + daysInMonth) / 7).rounded(.up)) * 7
        let gridStart = addDays(-offset, to: first)
        return (0..<cells).map { addDays($0, to: gridStart) }
    }

    /// 요일 머리글 (첫 요일 설정 반영).
    static var weekdaySymbols: [String] {
        let cal = calendar
        let symbols = cal.veryShortStandaloneWeekdaySymbols // 일 월 화 ...
        let shift = cal.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }
}
