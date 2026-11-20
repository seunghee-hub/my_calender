import SwiftUI

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

enum Palette {
    static let colors: [String] = [
        "#FF9500", "#AF52DE", "#34C759", "#007AFF", "#FF3B30",
        "#FF2D55", "#5AC8FA", "#30B0C7", "#A2845E", "#8E8E93",
    ]

    static let symbols: [String] = [
        "fork.knife", "cup.and.saucer", "moon.stars", "figure.run",
        "dumbbell", "building.columns", "briefcase", "person.2",
        "phone", "airplane", "cross.case", "book",
        "graduationcap", "cart", "car", "star",
    ]
}

extension QuickTag {
    var color: Color { Color(hex: colorHex) }
}

extension CalendarEvent {
    var color: Color { tag?.color ?? .accentColor }
}
