import Foundation
import SwiftData

/// 한 번 누르면 일정이 만들어지는 "빠른 입력 태그" (예: 점심, 저녁, 운동, 재판).
@Model
final class QuickTag {
    var name: String = ""
    var colorHex: String = "#FF9500"
    var symbol: String = "tag"
    /// 켜져 있으면 누를 때 이름(예: 약속 상대, 사건명)을 입력받은 뒤 저장한다.
    var asksForName: Bool = false
    /// 이름 입력칸에 보여줄 안내 문구.
    var namePrompt: String = "이름"
    /// 꺼져 있으면 누를 때마다 시간을 직접 고른다 (예: 재판).
    var hasDefaultTime: Bool = true
    /// 자정부터의 분 (12:00 = 720).
    var startMinute: Int = 720
    var endMinute: Int = 780
    var sortOrder: Int = 0

    @Relationship(deleteRule: .nullify, inverse: \CalendarEvent.tag)
    var events: [CalendarEvent]? = []

    init(
        name: String,
        colorHex: String,
        symbol: String,
        asksForName: Bool,
        namePrompt: String = "이름",
        hasDefaultTime: Bool,
        startMinute: Int = 720,
        endMinute: Int = 780,
        sortOrder: Int
    ) {
        self.name = name
        self.colorHex = colorHex
        self.symbol = symbol
        self.asksForName = asksForName
        self.namePrompt = namePrompt
        self.hasDefaultTime = hasDefaultTime
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.sortOrder = sortOrder
    }

    /// 주어진 날짜에 이 태그의 기본 시간대. 기본 시간이 없으면 nil.
    func defaultRange(on day: Date) -> (start: Date, end: Date)? {
        guard hasDefaultTime else { return nil }
        return DateTools.range(on: day, startMinute: startMinute, endMinute: endMinute)
    }

    /// "12:00–13:00" 또는 기본 시간이 없으면 nil.
    var timeText: String? {
        guard hasDefaultTime else { return nil }
        return "\(DateTools.hm(minutes: startMinute))–\(DateTools.hm(minutes: endMinute))"
    }

    /// 이름이 있으면 "점심 · 김대리", 없으면 "점심".
    func eventTitle(with input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? name : "\(name) · \(trimmed)"
    }
}
