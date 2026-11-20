import SwiftUI
import SwiftData

@main
struct RoutineCalendarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CalendarEvent.self, QuickTag.self])
    }
}
