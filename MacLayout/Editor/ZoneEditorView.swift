import SwiftUI

struct ZoneEditorView: View {
    @Binding var root: ZoneNode
    var onChanged: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Click a zone to split it. Drag dividers to resize. Right-click to remove.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset") {
                    root = .leaf(id: UUID())
                    onChanged()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            RecursiveZoneView(node: $root, isRoot: true, onChanged: onChanged, onRemove: nil)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

/// Recursively renders the zone tree using native SwiftUI layout
struct RecursiveZoneView: View {
    @Binding var node: ZoneNode
    let isRoot: Bool
    var onChanged: () -> Void
    var onRemove: (() -> Void)?

    var body: some View {
        switch node {
        case .leaf(let id):
            LeafZoneView(
                id: id,
                onSplitVertical: {
                    node = node.splitLeaf(leafID: id, direction: .vertical)
                    onChanged()
                },
                onSplitHorizontal: {
                    node = node.splitLeaf(leafID: id, direction: .horizontal)
                    onChanged()
                },
                onRemove: isRoot ? nil : onRemove
            )

        case .split(let splitID, let direction, let ratio, _, _):
            SplitContainerView(
                direction: direction,
                ratio: ratio,
                onRatioChanged: { newRatio in
                    node = node.updateRatio(splitID: splitID, newRatio: newRatio)
                    onChanged()
                },
                first: {
                    RecursiveZoneView(
                        node: firstChildBinding(),
                        isRoot: false,
                        onChanged: onChanged,
                        onRemove: {
                            // Remove first child → replace split with second child
                            if case .split(_, _, _, _, let second) = node {
                                node = second
                                onChanged()
                            }
                        }
                    )
                },
                second: {
                    RecursiveZoneView(
                        node: secondChildBinding(),
                        isRoot: false,
                        onChanged: onChanged,
                        onRemove: {
                            // Remove second child → replace split with first child
                            if case .split(_, _, _, let first, _) = node {
                                node = first
                                onChanged()
                            }
                        }
                    )
                }
            )
        }
    }

    private func firstChildBinding() -> Binding<ZoneNode> {
        Binding(
            get: {
                if case .split(_, _, _, let first, _) = node { return first }
                return node
            },
            set: { newValue in
                if case .split(let id, let dir, let ratio, _, let second) = node {
                    node = .split(id: id, direction: dir, ratio: ratio, first: newValue, second: second)
                }
            }
        )
    }

    private func secondChildBinding() -> Binding<ZoneNode> {
        Binding(
            get: {
                if case .split(_, _, _, _, let second) = node { return second }
                return node
            },
            set: { newValue in
                if case .split(let id, let dir, let ratio, let first, _) = node {
                    node = .split(id: id, direction: dir, ratio: ratio, first: first, second: newValue)
                }
            }
        )
    }
}

/// A container that lays out two children with a draggable divider
struct SplitContainerView<First: View, Second: View>: View {
    let direction: SplitDirection
    let ratio: Double
    let onRatioChanged: (Double) -> Void
    @ViewBuilder let first: First
    @ViewBuilder let second: Second

    @State private var dragStartRatio: Double = 0

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let dividerSize: CGFloat = 8
            switch direction {
            case .vertical:
                let firstWidth = (size.width - dividerSize) * ratio
                let secondWidth = (size.width - dividerSize) * (1 - ratio)
                HStack(spacing: 0) {
                    first
                        .frame(width: firstWidth)
                        .clipped()

                    dividerView(isVertical: true, totalSize: size.width - dividerSize)

                    second
                        .frame(width: secondWidth)
                        .clipped()
                }
            case .horizontal:
                let firstHeight = (size.height - dividerSize) * ratio
                let secondHeight = (size.height - dividerSize) * (1 - ratio)
                VStack(spacing: 0) {
                    first
                        .frame(height: firstHeight)
                        .clipped()

                    dividerView(isVertical: false, totalSize: size.height - dividerSize)

                    second
                        .frame(height: secondHeight)
                        .clipped()
                }
            }
        }
    }

    private func dividerView(isVertical: Bool, totalSize: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.primary.opacity(0.001))
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.35))
                .frame(width: isVertical ? 3 : 28, height: isVertical ? 28 : 3)
        }
        .frame(width: isVertical ? 8 : nil, height: isVertical ? nil : 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Use startLocation to compute absolute ratio
                    let offset = isVertical ? value.translation.width : value.translation.height
                    let newRatio = dragStartRatio + offset / totalSize
                    onRatioChanged(max(0.1, min(0.9, newRatio)))
                }
                .onEnded { _ in }
        )
        .onAppear { dragStartRatio = ratio }
        .onChange(of: ratio) { _, newValue in
            // Keep in sync when not dragging
            dragStartRatio = newValue
        }
        .onHover { hovering in
            if hovering {
                if isVertical { NSCursor.resizeLeftRight.push() }
                else { NSCursor.resizeUpDown.push() }
            } else {
                NSCursor.pop()
            }
        }
    }
}
