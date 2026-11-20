import SwiftUI
import SwiftData

/// 선택한 날짜의 일정 목록.
struct DayEventsView: View {
    @Environment(\.modelContext) private var context
    @Query private var events: [CalendarEvent]
    let onSelect: (CalendarEvent) -> Void

    init(date: Date, onSelect: @escaping (CalendarEvent) -> Void) {
        self.onSelect = onSelect
        let start = Calendar.current.startOfDay(for: date)
        let end = DateTools.addDays(1, to: start)
        _events = Query(
            filter: #Predicate<CalendarEvent> { event in
                event.startDate < end && (event.endDate > start || event.startDate >= start)
            },
            sort: \CalendarEvent.startDate
        )
    }

    /// 하루 종일 일정이 먼저, 나머지는 시작 시간 순.
    private var sortedEvents: [CalendarEvent] {
        events.filter(\.isAllDay) + events.filter { !$0.isAllDay }
    }

    var body: some View {
        if events.isEmpty {
            ContentUnavailableView(
                "일정 없음",
                systemImage: "calendar",
                description: Text("위의 버튼을 누르면 바로 추가돼요.")
            )
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(sortedEvents) { event in
                    Button {
                        onSelect(event)
                    } label: {
                        EventRow(event: event)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            context.delete(event)
                            try? context.save()
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.color)
                .frame(width: 4, height: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title.isEmpty ? "(제목 없음)" : event.title)
                    .font(.body.weight(.medium))
                Text(event.timeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let tag = event.tag {
                Image(systemName: tag.symbol)
                    .foregroundStyle(tag.color)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}
