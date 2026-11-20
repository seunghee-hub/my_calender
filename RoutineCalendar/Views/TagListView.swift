import SwiftUI
import SwiftData

/// 빠른 입력 태그 목록: 추가, 편집, 순서 변경, 삭제.
struct TagListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \QuickTag.sortOrder) private var tags: [QuickTag]
    @State private var editorTarget: TagEditorTarget?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(tags) { tag in
                        Button {
                            editorTarget = TagEditorTarget(tag: tag)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: tag.symbol)
                                    .foregroundStyle(tag.color)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tag.name)
                                        .foregroundStyle(.primary)
                                    Text(summary(for: tag))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onMove(perform: move)
                    .onDelete(perform: delete)

                    Button {
                        editorTarget = TagEditorTarget(tag: nil)
                    } label: {
                        Label("태그 추가", systemImage: "plus.circle.fill")
                    }
                } footer: {
                    Text("태그를 누르면 정해둔 시간에 바로 일정이 생겨요. 기본 시간이 없는 태그는 누를 때 시간을 고릅니다. 태그를 지워도 이미 만든 일정은 남아요.")
                }
            }
            .navigationTitle("태그 관리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
            .sheet(item: $editorTarget) { target in
                TagEditorView(tag: target.tag)
            }
        }
    }

    private func summary(for tag: QuickTag) -> String {
        let time = tag.timeText ?? "누를 때 시간 선택"
        return tag.asksForName ? "\(time) · 이름 입력" : "\(time) · 바로 저장"
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = tags
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, tag) in ordered.enumerated() {
            tag.sortOrder = index
        }
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(tags[index])
        }
        try? context.save()
    }
}
