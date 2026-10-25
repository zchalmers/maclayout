import Cocoa

class OverlayManager {
    static let shared = OverlayManager()

    /// Keyed by screen's displayID (CGDirectDisplayID)
    private var overlayControllers: [UInt32: OverlayWindowController] = [:]

    func show(on screen: NSScreen, zones: [(UUID, CGRect)], highlightedZoneID: UUID?) {
        let controller = overlayController(for: screen)
        controller.updateZones(zones, highlightedZoneID: highlightedZoneID)
        controller.show()

        // Hide overlays on other screens
        let key = screenKey(screen)
        for (otherKey, otherController) in overlayControllers where otherKey != key {
            otherController.hide()
        }
    }

    func hideAll() {
        for (_, controller) in overlayControllers {
            controller.hide()
        }
    }

    private func overlayController(for screen: NSScreen) -> OverlayWindowController {
        let key = screenKey(screen)
        if let existing = overlayControllers[key],
           existing.window?.frame == screen.frame {
            return existing
        }
        // Recreate if screen frame changed or first time
        let controller = OverlayWindowController(screen: screen)
        overlayControllers[key] = controller
        return controller
    }

    private func screenKey(_ screen: NSScreen) -> UInt32 {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32) ?? 0
    }
}
