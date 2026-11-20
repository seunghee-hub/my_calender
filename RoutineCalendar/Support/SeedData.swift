import Foundation
import SwiftData

enum SeedData {
    private static let key = "didSeedDefaultTags.v1"

    /// 처음 실행할 때 기본 태그(점심, 저녁, 운동, 재판)를 만든다.
    static func seedIfNeeded(_ context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<QuickTag>())) ?? 0
        if existing == 0 {
            let tags = [
                QuickTag(name: "점심", colorHex: "#FF9500", symbol: "fork.knife",
                         asksForName: true, namePrompt: "누구랑? (예: 김대리)",
                         hasDefaultTime: true, startMinute: 12 * 60, endMinute: 13 * 60, sortOrder: 0),
                QuickTag(name: "저녁", colorHex: "#AF52DE", symbol: "moon.stars",
                         asksForName: true, namePrompt: "누구랑? (예: 대학 동기)",
                         hasDefaultTime: true, startMinute: 18 * 60 + 30, endMinute: 20 * 60, sortOrder: 1),
                QuickTag(name: "운동", colorHex: "#34C759", symbol: "figure.run",
                         asksForName: false,
                         hasDefaultTime: true, startMinute: 19 * 60, endMinute: 20 * 60, sortOrder: 2),
                QuickTag(name: "재판", colorHex: "#007AFF", symbol: "building.columns",
                         asksForName: true, namePrompt: "사건명 (선택)",
                         hasDefaultTime: false, sortOrder: 3),
            ]
            tags.forEach { context.insert($0) }
            try? context.save()
        }
        UserDefaults.standard.set(true, forKey: key)
    }
}
