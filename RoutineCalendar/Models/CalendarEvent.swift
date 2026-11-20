import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var title: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date()
    var isAllDay: Bool = false
    var notes: String = ""
    var createdAt: Date = Date()
    var tag: QuickTag?

    init(title: String, startDate: Date, endDate: Date, isAllDay: Bool = false, notes: String = "") {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.notes = notes
        self.createdAt = Date()
    }

    var timeText: String {
        if isAllDay { return "하루 종일" }
        // 자정에 끝나는 일정은 같은 날로 본다.
        let lastMoment = endDate > startDate ? endDate.addingTimeInterval(-1) : endDate
        if Calendar.current.isDate(startDate, inSameDayAs: lastMoment) {
            return "\(DateTools.hm(startDate)) – \(DateTools.hm(endDate))"
        }
        return "\(DateTools.shortDay(startDate)) \(DateTools.hm(startDate)) – \(DateTools.shortDay(endDate)) \(DateTools.hm(endDate))"
    }
}
