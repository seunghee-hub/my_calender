import SwiftUI

/// 점심 / 저녁 / 사용자 태그 버튼 줄.
struct QuickEntryBar: View {
    let tags: [QuickTag]
    let onTap: (QuickTag) -> Void
    let onChooseTime: (QuickTag) -> Void
    let onEditTag: (QuickTag) -> Void
    let onAddTag: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags) { tag in
                    Button {
                        onTap(tag)
                    } label: {
                        VStack(spacing: 2) {
                            Label(tag.name, systemImage: tag.symbol)
                                .font(.subheadline.bold())
                            Text(tag.timeText ?? "시간 선택")
                                .font(.caption2)
                                .opacity(0.8)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(tag.color)
                        .background(tag.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            onChooseTime(tag)
                        } label: {
                            Label("다른 시간으로 추가", systemImage: "clock")
                        }
                        Button {
                            onEditTag(tag)
                        } label: {
                            Label("태그 편집", systemImage: "pencil")
                        }
                    }
                }

                Button(action: onAddTag) {
                    Label("태그", systemImage: "plus")
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 15)
                        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }
}
