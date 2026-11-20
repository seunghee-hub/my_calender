import SwiftUI
import SwiftData

/// 태그 만들기 / 편집: 이름, 색, 아이콘, 기본 시간, 이름 입력 여부.
struct TagEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \QuickTag.sortOrder) private var allTags: [QuickTag]

    private let tag: QuickTag?

    @State private var name: String
    @State private var colorHex: String
    @State private var symbol: String
    @State private var asksForName: Bool
    @State private var namePrompt: String
    @State private var hasDefaultTime: Bool
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var confirmDelete = false

    init(tag: QuickTag?) {
        self.tag = tag
        _name = State(initialValue: tag?.name ?? "")
        _colorHex = State(initialValue: tag?.colorHex ?? Palette.colors[2])
        _symbol = State(initialValue: tag?.symbol ?? "star")
        _asksForName = State(initialValue: tag?.asksForName ?? false)
        _namePrompt = State(initialValue: tag?.namePrompt ?? "이름")
        _hasDefaultTime = State(initialValue: tag?.hasDefaultTime ?? true)
        _startTime = State(initialValue: DateTools.dateForMinutes(tag?.startMinute ?? 9 * 60))
        _endTime = State(initialValue: DateTools.dateForMinutes(tag?.endMinute ?? 10 * 60))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: symbol)
                            .font(.title2)
                            .foregroundStyle(Color(hex: colorHex))
                            .frame(width: 36)
                        TextField("태그 이름 (예: 운동)", text: $name)
                    }
                }

                Section("기본 시간") {
                    Toggle("기본 시간 사용", isOn: $hasDefaultTime.animation())
                    if hasDefaultTime {
                        DatePicker("시작", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("종료", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    Toggle("누를 때 이름 입력받기", isOn: $asksForName.animation())
                    if asksForName {
                        TextField("입력칸 안내 문구 (예: 누구랑?)", text: $namePrompt)
                    }
                } footer: {
                    Text(footerText)
                }

                Section("색") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Palette.colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if hex == colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("아이콘") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(Palette.symbols, id: \.self) { s in
                            Image(systemName: s)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(s == symbol ? Color.white : Color(hex: colorHex))
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(s == symbol ? Color(hex: colorHex) : Color.secondary.opacity(0.1))
                                )
                                .onTapGesture { symbol = s }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if tag != nil {
                    Section {
                        Button("태그 삭제", role: .destructive) {
                            confirmDelete = true
                        }
                    }
                }
            }
            .navigationTitle(tag == nil ? "새 태그" : "태그 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: save)
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog("이 태그를 삭제할까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    if let tag {
                        context.delete(tag)
                        try? context.save()
                    }
                    dismiss()
                }
            } message: {
                Text("이미 만든 일정은 지워지지 않아요.")
            }
        }
    }

    private var footerText: String {
        switch (hasDefaultTime, asksForName) {
        case (true, false): return "누르는 즉시 기본 시간으로 저장돼요."
        case (true, true): return "누르면 이름만 입력하고 바로 저장돼요."
        case (false, false): return "누를 때 시간을 골라서 저장해요."
        case (false, true): return "누를 때 이름과 시간을 입력해요."
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let prompt = namePrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        let target: QuickTag
        if let tag {
            target = tag
        } else {
            let nextOrder = (allTags.map(\.sortOrder).max() ?? -1) + 1
            target = QuickTag(name: trimmed, colorHex: colorHex, symbol: symbol,
                              asksForName: asksForName, hasDefaultTime: hasDefaultTime,
                              sortOrder: nextOrder)
            context.insert(target)
        }
        target.name = trimmed
        target.colorHex = colorHex
        target.symbol = symbol
        target.asksForName = asksForName
        target.namePrompt = prompt.isEmpty ? "이름" : prompt
        target.hasDefaultTime = hasDefaultTime
        target.startMinute = DateTools.minutes(of: startTime)
        target.endMinute = DateTools.minutes(of: endTime)
        try? context.save()
        dismiss()
    }
}
