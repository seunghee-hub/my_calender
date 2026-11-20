import SwiftUI
import SwiftData

/// 일반 일정(단발성) 추가 및 기존 일정 편집.
struct EventEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \QuickTag.sortOrder) private var tags: [QuickTag]

    private let event: CalendarEvent?

    @State private var title: String
    @State private var start: Date
    @State private var end: Date
    @State private var isAllDay: Bool
    @State private var notes: String
    @State private var tag: QuickTag?
    @State private var confirmDelete = false

    init(event: CalendarEvent?, date: Date) {
        self.event = event
        if let event {
            _title = State(initialValue: event.title)
            _start = State(initialValue: event.startDate)
            // 하루 종일 일정은 다음 날 0시에 끝나도록 저장돼 있으므로 마지막 날로 되돌려 보여준다.
            _end = State(initialValue: event.isAllDay
                         ? max(event.startDate, event.endDate.addingTimeInterval(-1))
                         : event.endDate)
            _isAllDay = State(initialValue: event.isAllDay)
            _notes = State(initialValue: event.notes)
            _tag = State(initialValue: event.tag)
        } else {
            let range = DateTools.suggestedRange(on: date)
            _title = State(initialValue: "")
            _start = State(initialValue: range.start)
            _end = State(initialValue: range.end)
            _isAllDay = State(initialValue: false)
            _notes = State(initialValue: "")
            _tag = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("제목", text: $title)
                    Picker("태그", selection: $tag) {
                        Text("없음").tag(QuickTag?.none)
                        ForEach(tags) { t in
                            Label(t.name, systemImage: t.symbol).tag(QuickTag?.some(t))
                        }
                    }
                }

                Section {
                    Toggle("하루 종일", isOn: $isAllDay)
                    DatePicker("시작", selection: $start,
                               displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                    DatePicker("종료", selection: $end, in: start...,
                               displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                }

                Section("메모") {
                    TextField("메모", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                if event != nil {
                    Section {
                        Button("일정 삭제", role: .destructive) {
                            confirmDelete = true
                        }
                    }
                }
            }
            .navigationTitle(event == nil ? "새 일정" : "일정 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(event == nil ? "추가" : "저장", action: save)
                        .bold()
                }
            }
            .onChange(of: start) { _, newValue in
                if end < newValue { end = newValue.addingTimeInterval(60 * 60) }
            }
            .onChange(of: tag) { _, newTag in
                // 새 일정에서 기본 시간이 있는 태그를 고르면 그 시간대로 맞춘다.
                guard event == nil, let newTag, let range = newTag.defaultRange(on: start) else { return }
                start = range.start
                end = range.end
            }
            .confirmationDialog("이 일정을 삭제할까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    if let event {
                        context.delete(event)
                        try? context.save()
                    }
                    dismiss()
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmed.isEmpty ? (tag?.name ?? "새 일정") : trimmed
        let cal = Calendar.current
        var finalStart = start
        var finalEnd = max(end, start)
        if isAllDay {
            finalStart = cal.startOfDay(for: start)
            finalEnd = DateTools.addDays(1, to: cal.startOfDay(for: max(end, start)))
        }

        let target: CalendarEvent
        if let event {
            target = event
        } else {
            target = CalendarEvent(title: finalTitle, startDate: finalStart, endDate: finalEnd)
            context.insert(target)
        }
        target.title = finalTitle
        target.startDate = finalStart
        target.endDate = finalEnd
        target.isAllDay = isAllDay
        target.notes = notes
        target.tag = tag
        try? context.save()
        dismiss()
    }
}
