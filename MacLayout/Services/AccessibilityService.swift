import Cocoa
import ApplicationServices

class AccessibilityService {
    static let shared = AccessibilityService()

    /// Get the frontmost window (the one being dragged)
    func getFrontmostWindow() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?
        let appResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        guard appResult == .success, let app = focusedApp else { return nil }

        var focusedWindow: AnyObject?
        let winResult = AXUIElementCopyAttributeValue(app as! AXUIElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        guard winResult == .success else { return nil }

        return (focusedWindow as! AXUIElement)
    }

    /// Move and resize a window to fill the given rect (in Quartz/screen coordinates, top-left origin)
    func setWindowFrame(_ window: AXUIElement, to rect: CGRect) {
        var point = CGPoint(x: rect.origin.x, y: rect.origin.y)
        if let posValue = AXValueCreate(.cgPoint, &point) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        }

        var size = CGSize(width: rect.width, height: rect.height)
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }

    /// Get the current frame of a window
    func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var posValue: AnyObject?
        var sizeValue: AnyObject?

        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success else {
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero

        AXValueGetValue(posValue as! AXValue, .cgPoint, &point)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)

        return CGRect(origin: point, size: size)
    }
}
