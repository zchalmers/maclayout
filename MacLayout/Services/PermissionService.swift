import Cocoa

class PermissionService {
    static let shared = PermissionService()

    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompt for accessibility. Returns true if already granted.
    @discardableResult
    func requestAccessibilityIfNeeded() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Poll until accessibility is granted, then call the completion handler.
    func waitForAccessibility(completion: @escaping () -> Void) {
        if isAccessibilityGranted {
            completion()
            return
        }

        // Poll every 1 second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                completion()
            }
        }
    }
}
