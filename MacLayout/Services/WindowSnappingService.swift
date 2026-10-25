import Cocoa

class WindowSnappingService {
    static let shared = WindowSnappingService()

    private let dragService = DragDetectionService.shared
    private let accessibilityService = AccessibilityService.shared
    private let overlayManager = OverlayManager.shared
    private let appState = AppState.shared

    private var highlightedZoneID: UUID?

    func start() {
        dragService.onStateChanged = { [weak self] state, mouseLocation in
            self?.handleStateChange(state: state, mouseLocation: mouseLocation)
        }
        dragService.start()
    }

    func stop() {
        dragService.stop()
        overlayManager.hideAll()
    }

    private func handleStateChange(state: DragState, mouseLocation: CGPoint) {
        guard let layout = appState.selectedLayout else { return }

        switch state {
        case .activeWithOverlay:
            // Determine which screen the mouse is on
            let screen = screenForQuartzPoint(mouseLocation)
            let screenFrame = screenVisibleFrame(screen)

            // Find which zone the mouse is hovering over
            let zoneID = layout.root.zoneAt(point: mouseLocation, in: screenFrame)
            highlightedZoneID = zoneID

            // Show overlay
            let zones = layout.root.resolveRects(in: screenFrame)
            overlayManager.show(on: screen, zones: zones, highlightedZoneID: zoneID)

        case .dragging:
            overlayManager.hideAll()
            highlightedZoneID = nil

        case .idle:
            // Mouse up while overlay is active — snap the window
            if let zoneID = highlightedZoneID {
                snapFrontmostWindow(to: zoneID, layout: layout, mouseLocation: mouseLocation)
            }
            overlayManager.hideAll()
            highlightedZoneID = nil
        }
    }

    private func snapFrontmostWindow(to zoneID: UUID, layout: Layout, mouseLocation: CGPoint) {
        let screen = screenForQuartzPoint(mouseLocation)
        let screenFrame = screenVisibleFrame(screen)
        let zones = layout.root.resolveRects(in: screenFrame)

        guard let (_, targetRect) = zones.first(where: { $0.0 == zoneID }) else { return }

        // Small delay to let the drag finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let window = self?.accessibilityService.getFrontmostWindow() else { return }
            self?.accessibilityService.setWindowFrame(window, to: targetRect)
        }
    }

    /// Find which screen contains the given Quartz coordinate point
    private func screenForQuartzPoint(_ point: CGPoint) -> NSScreen {
        // Convert Quartz (top-left) to AppKit (bottom-left) for NSScreen comparison
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let appKitPoint = NSPoint(x: point.x, y: primaryHeight - point.y)

        for screen in NSScreen.screens {
            if screen.frame.contains(appKitPoint) {
                return screen
            }
        }
        return NSScreen.main ?? NSScreen.screens[0]
    }

    /// Get the visible frame in Quartz coordinates (top-left origin)
    private func screenVisibleFrame(_ screen: NSScreen) -> CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let visibleFrame = screen.visibleFrame
        // Convert from AppKit (bottom-left) to Quartz (top-left)
        let quartzY = primaryHeight - visibleFrame.origin.y - visibleFrame.height
        return CGRect(x: visibleFrame.origin.x, y: quartzY,
                     width: visibleFrame.width, height: visibleFrame.height)
    }
}
