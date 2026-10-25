import SwiftUI

struct LeafZoneView: View {
    let id: UUID
    var onSplitVertical: () -> Void
    var onSplitHorizontal: () -> Void
    var onRemove: (() -> Void)?

    @State private var isHovering = false

    private var zoneColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo]
        let index = abs(id.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(zoneColor.opacity(isHovering ? 0.25 : 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(zoneColor.opacity(isHovering ? 0.6 : 0.25), lineWidth: 1.5)
                )

            if isHovering {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Button(action: onSplitVertical) {
                            Label("Split V", systemImage: "rectangle.split.2x1")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)

                        Button(action: onSplitHorizontal) {
                            Label("Split H", systemImage: "rectangle.split.1x2")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }

                    if let onRemove = onRemove {
                        Button(role: .destructive, action: onRemove) {
                            Label("Remove", systemImage: "xmark")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button("Split Vertically") { onSplitVertical() }
            Button("Split Horizontally") { onSplitHorizontal() }
            if let onRemove = onRemove {
                Divider()
                Button("Remove Zone", role: .destructive) { onRemove() }
            }
        }
    }
}
