import Cocoa
import SwiftUI

class LayoutEditorWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacLayout Editor"
        window.center()
        window.setFrameAutosaveName("LayoutEditor")
        window.minSize = NSSize(width: 600, height: 450)

        super.init(window: window)

        let editorView = LayoutEditorView()
        window.contentView = NSHostingView(rootView: editorView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}
