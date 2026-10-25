import Cocoa

class OverlayWindowController: NSWindowController {
    private let overlayView: OverlayView

    init(screen: NSScreen) {
        let overlayView = OverlayView(frame: screen.frame)
        self.overlayView = overlayView

        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = false
        panel.contentView = overlayView
        panel.alphaValue = 0

        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func updateZones(_ zones: [(UUID, CGRect)], highlightedZoneID: UUID?) {
        overlayView.zones = zones
        overlayView.highlightedZoneID = highlightedZoneID
        overlayView.needsDisplay = true
    }

    func show() {
        guard let panel = window else { return }
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1.0
        }
    }

    func hide() {
        guard let panel = window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }
}
