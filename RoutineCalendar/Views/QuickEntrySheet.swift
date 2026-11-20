import SwiftUI

/// 빠른 입력: 이름만 쓰고 저장. 기본 시간이 없는 태그(예: 재판)는 시간도 고른다.
struct QuickEntrySheet: View {
    let tag: QuickTag
    let date: Date
    let chooseTime: Bool
    let onSave: (String, Date, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var start: Date
    @State private var end: Date
    @FocusState private var nameFocused: Bool

    init(tag: QuickTag, date: Date, chooseTime: Bool, onSave: @escaping (String, Date, Date) -> Void) {
        self.tag = tag
        self.date = date
        self.chooseTime = chooseTime || !tag.hasDefaultTime
        self.onSave = onSave
        let range = tag.defaultRange(on: date) ?? DateTools.suggestedRange(on: date)
        _start = State(initialValue: range.start)
        _end = State(initialValue: range.end)
    }

    var body: some View {
        NavigationStack {
            Form {
                if tag.asksForName {
                    Section {
                        TextField(tag.namePrompt, text: $name)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .onSubmit(save)
                    }
                }
                if chooseTime {
                    Section {
                        DatePicker("시작", selection: $start, displayedComponents: .hourAndMinute)
                        DatePicker("종료", selection: $end, in: start..., displayedComponents: .hourAndMinute)
                    }
                } else {
                    Section {
                        LabeledContent("시간", value: "\(DateTools.hm(start)) – \(DateTools.hm(end))")
                    }
                }
            }
            .navigationTitle("\(DateTools.day(date)) \(tag.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: save)
                        .bold()
                }
            }
            .onChange(of: start) { oldValue, newValue in
                // 시작을 옮기면 길이를 유지한 채 종료도 같이 옮긴다.
                let duration = max(end.timeIntervalSince(oldValue), 15 * 60)
                end = newValue.addingTimeInterval(duration)
            }
            .task {
                guard tag.asksForName, !chooseTime else { return }
                try? await Task.sleep(for: .milliseconds(300))
                nameFocused = true
            }
        }
        .presentationDetents(detents)
    }

    private var detents: Set<PresentationDetent> {
        chooseTime ? [.medium, .large] : [.height(240)]
    }

    private func save() {
        onSave(tag.eventTitle(with: name), start, max(end, start))
        dismiss()
    }
}
