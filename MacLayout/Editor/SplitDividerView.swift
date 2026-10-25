import SwiftUI

struct SplitDividerView: View {
    let direction: SplitDirection
    let rect: CGRect
    let ratio: Double
    var onRatioChanged: (Double) -> Void

    @State private var isDragging = false

    private var dividerThickness: CGFloat { 12 }

    var body: some View {
        let position = dividerPosition()

        Rectangle()
            .fill(isDragging ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.001))
            .overlay(
                dividerHandle()
            )
            .frame(
                width: direction == .vertical ? dividerThickness : rect.width,
                height: direction == .horizontal ? dividerThickness : rect.height
            )
            .position(x: position.x, y: position.y)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let newRatio: Double
                        switch direction {
                        case .vertical:
                            newRatio = (value.location.x - rect.origin.x) / rect.width
                        case .horizontal:
                            newRatio = (value.location.y - rect.origin.y) / rect.height
                        }
                        onRatioChanged(max(0.1, min(0.9, newRatio)))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onHover { hovering in
                if hovering {
                    switch direction {
                    case .vertical:
                        NSCursor.resizeLeftRight.push()
                    case .horizontal:
                        NSCursor.resizeUpDown.push()
                    }
                } else {
                    NSCursor.pop()
                }
            }
    }

    private func dividerPosition() -> CGPoint {
        switch direction {
        case .vertical:
            return CGPoint(x: rect.origin.x + rect.width * ratio, y: rect.midY)
        case .horizontal:
            return CGPoint(x: rect.midX, y: rect.origin.y + rect.height * ratio)
        }
    }

    @ViewBuilder
    private func dividerHandle() -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isDragging ? Color.accentColor : Color.secondary.opacity(0.4))
            .frame(
                width: direction == .vertical ? 4 : 32,
                height: direction == .horizontal ? 4 : 32
            )
    }
}
