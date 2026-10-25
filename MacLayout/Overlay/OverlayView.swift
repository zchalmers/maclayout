import Cocoa

class OverlayView: NSView {
    var zones: [(UUID, CGRect)] = []
    var highlightedZoneID: UUID?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        guard let windowFrame = window?.frame else { return }

        // Semi-transparent dark background
        context.setFillColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        context.fill(bounds)

        let primaryHeight = NSScreen.screens.first?.frame.height ?? bounds.height

        for (id, quartzRect) in zones {
            // Zone rects are in Quartz coordinates (top-left origin, global).
            // The NSView draws in local coords (bottom-left origin, relative to window).
            // Window frame is in AppKit screen coords (bottom-left origin, global).
            //
            // Convert: Quartz global → AppKit global → view-local
            let appKitGlobalY = primaryHeight - quartzRect.origin.y - quartzRect.height
            let localX = quartzRect.origin.x - windowFrame.origin.x
            let localY = appKitGlobalY - windowFrame.origin.y

            let localRect = NSRect(
                x: localX,
                y: localY,
                width: quartzRect.width,
                height: quartzRect.height
            )

            let isHighlighted = (id == highlightedZoneID)
            let insetRect = localRect.insetBy(dx: 3, dy: 3)

            guard insetRect.width > 0 && insetRect.height > 0 else { continue }

            let path = NSBezierPath(roundedRect: insetRect, xRadius: 8, yRadius: 8)

            // Fill
            let fillColor = isHighlighted
                ? NSColor.systemBlue.withAlphaComponent(0.35)
                : NSColor.white.withAlphaComponent(0.08)
            fillColor.setFill()
            path.fill()

            // Stroke
            let strokeColor = isHighlighted
                ? NSColor.systemBlue.withAlphaComponent(0.8)
                : NSColor.white.withAlphaComponent(0.25)
            strokeColor.setStroke()
            path.lineWidth = isHighlighted ? 3 : 1.5
            path.stroke()
        }
    }
}
