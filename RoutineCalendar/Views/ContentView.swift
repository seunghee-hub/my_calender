import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \QuickTag.sortOrder) private var tags: [QuickTag]

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth = DateTools.startOfMonth(Date())
    @State private var quickRequest: QuickRequest?
    @State private var editorTarget: EditorTarget?
    @State private var tagEditorTarget: TagEditorTarget?
    @State private var showTagList = false
    @State private var toast: ToastData?

    var body: some View {
        NavigationStack {
            Group {
                if sizeClass == .regular {
                    // 아이패드: 왼쪽 달력, 오른쪽 하루 일정
                    HStack(alignment: .top, spacing: 0) {
                        VStack {
                            calendar
                            Spacer()
                        }
                        .frame(maxWidth: 460)
                        Divider()
                        dayPanel
                    }
                } else {
                    // 아이폰: 위 달력, 아래 하루 일정
                    VStack(spacing: 0) {
                        calendar
                        Divider()
                        dayPanel
                    }
                }
            }
            .navigationTitle("루틴 캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("오늘") { goToToday() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showTagList = true
                    } label: {
                        Label("태그 관리", systemImage: "tag")
                    }
                    Button {
                        editorTarget = .new(selectedDate)
                    } label: {
                        Label("일정 추가", systemImage: "plus")
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                ToastView(message: toast.message) {
                    undo(toast)
                }
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: toast)
        .task(id: toast?.id) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { toast = nil }
        }
        .sensoryFeedback(.success, trigger: toast?.id) { _, new in new != nil }
        .sheet(item: $quickRequest) { request in
            QuickEntrySheet(tag: request.tag, date: selectedDate, chooseTime: request.chooseTime) { title, start, end in
                addEvent(title: title, start: start, end: end, tag: request.tag)
            }
        }
        .sheet(item: $editorTarget) { target in
            switch target {
            case .new(let date):
                EventEditorView(event: nil, date: date)
            case .edit(let event):
                EventEditorView(event: event, date: event.startDate)
            }
        }
        .sheet(item: $tagEditorTarget) { target in
            TagEditorView(tag: target.tag)
        }
        .sheet(isPresented: $showTagList) {
            TagListView()
        }
        .task {
            SeedData.seedIfNeeded(context)
        }
    }

    private var calendar: some View {
        MonthCalendarView(month: $displayedMonth, selectedDate: $selectedDate)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
    }

    private var dayPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(DateTools.day(selectedDate))
                    .font(.headline)
                if Calendar.current.isDateInToday(selectedDate) {
                    Text("오늘")
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            QuickEntryBar(
                tags: tags,
                onTap: handleQuickTap,
                onChooseTime: { quickRequest = QuickRequest(tag: $0, chooseTime: true) },
                onEditTag: { tagEditorTarget = TagEditorTarget(tag: $0) },
                onAddTag: { tagEditorTarget = TagEditorTarget(tag: nil) }
            )
            .padding(.vertical, 10)

            DayEventsView(date: selectedDate) { event in
                editorTarget = .edit(event)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Actions

    private func goToToday() {
        let today = Calendar.current.startOfDay(for: Date())
        selectedDate = today
        displayedMonth = DateTools.startOfMonth(today)
    }

    private func handleQuickTap(_ tag: QuickTag) {
        if let range = tag.defaultRange(on: selectedDate), !tag.asksForName {
            // 기본 시간이 있고 이름도 필요 없으면 누르는 즉시 저장
            addEvent(title: tag.name, start: range.start, end: range.end, tag: tag)
        } else {
            quickRequest = QuickRequest(tag: tag, chooseTime: !tag.hasDefaultTime)
        }
    }

    private func addEvent(title: String, start: Date, end: Date, tag: QuickTag?) {
        let event = CalendarEvent(title: title, startDate: start, endDate: end)
        context.insert(event)
        event.tag = tag
        try? context.save()
        toast = ToastData(message: "\(title)  \(event.timeText) 추가됨", event: event)
    }

    private func undo(_ toast: ToastData) {
        context.delete(toast.event)
        try? context.save()
        self.toast = nil
    }
}

// MARK: - Sheet targets

struct QuickRequest: Identifiable {
    let id = UUID()
    let tag: QuickTag
    let chooseTime: Bool
}

struct TagEditorTarget: Identifiable {
    let id = UUID()
    let tag: QuickTag?
}

enum EditorTarget: Identifiable {
    case new(Date)
    case edit(CalendarEvent)

    var id: String {
        switch self {
        case .new(let date): return "new-\(date.timeIntervalSince1970)"
        case .edit(let event): return "edit-\(event.persistentModelID.hashValue)"
        }
    }
}

struct ToastData: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let event: CalendarEvent

    static func == (lhs: ToastData, rhs: ToastData) -> Bool { lhs.id == rhs.id }
}

#Preview {
    ContentView()
        .modelContainer(for: [CalendarEvent.self, QuickTag.self], inMemory: true)
}
