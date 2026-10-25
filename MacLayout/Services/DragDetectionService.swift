import Cocoa

enum DragState {
    case idle
    case dragging
    case activeWithOverlay
}

class DragDetectionService {
    static let shared = DragDetectionService()

    var onStateChanged: ((DragState, CGPoint) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var state: DragState = .idle
    private var shiftHeld = false
    private var lastMouseLocation: CGPoint = .zero

    func start() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask =
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo = userInfo else { return nil }
                let service = Unmanaged<DragDetectionService>.fromOpaque(userInfo).takeUnretainedValue()
                DispatchQueue.main.async {
                    service.handleEvent(type: type, event: event)
                }
                return nil
            },
            userInfo: userInfo
        ) else {
            print("Failed to create CGEventTap — Accessibility permission may not be granted")
            // Fallback to NSEvent global monitor
            setupFallbackMonitor()
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        state = .idle

        NSEvent.removeMonitor(flagsMonitor as Any)
        NSEvent.removeMonitor(mouseDragMonitor as Any)
        NSEvent.removeMonitor(mouseUpMonitor as Any)
        flagsMonitor = nil
        mouseDragMonitor = nil
        mouseUpMonitor = nil
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        let location = event.location // Quartz coordinates (top-left origin)
        lastMouseLocation = location

        switch type {
        case .leftMouseDown:
            // A drag might be starting
            break

        case .leftMouseDragged:
            if state == .idle {
                state = .dragging
            }
            // Check if shift is currently held
            let flags = CGEventFlags(rawValue: event.flags.rawValue)
            let shiftNow = flags.contains(.maskShift)

            if shiftNow && state == .dragging {
                state = .activeWithOverlay
                onStateChanged?(.activeWithOverlay, location)
            } else if shiftNow && state == .activeWithOverlay {
                // Update highlighted zone
                onStateChanged?(.activeWithOverlay, location)
            } else if !shiftNow && state == .activeWithOverlay {
                state = .dragging
                onStateChanged?(.dragging, location)
            }

        case .leftMouseUp:
            if state == .activeWithOverlay {
                // Snap the window
                onStateChanged?(.idle, location)
            }
            state = .idle

        case .flagsChanged:
            let flags = CGEventFlags(rawValue: event.flags.rawValue)
            shiftHeld = flags.contains(.maskShift)

            if shiftHeld && state == .dragging {
                state = .activeWithOverlay
                onStateChanged?(.activeWithOverlay, lastMouseLocation)
            } else if !shiftHeld && state == .activeWithOverlay {
                state = .dragging
                onStateChanged?(.dragging, lastMouseLocation)
            }

        default:
            break
        }
    }

    // MARK: - Fallback NSEvent Monitors

    private var flagsMonitor: Any?
    private var mouseDragMonitor: Any?
    private var mouseUpMonitor: Any?

    private func setupFallbackMonitor() {
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            self.shiftHeld = event.modifierFlags.contains(.shift)
            let loc = NSEvent.mouseLocation
            let quartzLoc = self.quartzPoint(from: loc)

            if self.shiftHeld && self.state == .dragging {
                self.state = .activeWithOverlay
                self.onStateChanged?(.activeWithOverlay, quartzLoc)
            } else if !self.shiftHeld && self.state == .activeWithOverlay {
                self.state = .dragging
                self.onStateChanged?(.dragging, quartzLoc)
            }
        }

        mouseDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            guard let self = self else { return }
            if self.state == .idle { self.state = .dragging }
            let loc = NSEvent.mouseLocation
            let quartzLoc = self.quartzPoint(from: loc)
            self.lastMouseLocation = quartzLoc

            if self.shiftHeld && self.state == .dragging {
                self.state = .activeWithOverlay
                self.onStateChanged?(.activeWithOverlay, quartzLoc)
            } else if self.shiftHeld && self.state == .activeWithOverlay {
                self.onStateChanged?(.activeWithOverlay, quartzLoc)
            }
        }

        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            guard let self = self else { return }
            if self.state == .activeWithOverlay {
                let loc = NSEvent.mouseLocation
                let quartzLoc = self.quartzPoint(from: loc)
                self.onStateChanged?(.idle, quartzLoc)
            }
            self.state = .idle
        }
    }

    /// Convert AppKit screen coordinates (bottom-left origin) to Quartz (top-left origin)
    private func quartzPoint(from appKitPoint: NSPoint) -> CGPoint {
        guard let primaryScreen = NSScreen.screens.first else { return CGPoint(x: appKitPoint.x, y: appKitPoint.y) }
        return CGPoint(x: appKitPoint.x, y: primaryScreen.frame.height - appKitPoint.y)
    }
}
