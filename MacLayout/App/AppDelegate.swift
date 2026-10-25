import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var editorWindowController: LayoutEditorWindowController?
    let appState = AppState.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.layoutStore.loadLayouts()

        if appState.selectedLayoutID == nil {
            appState.selectedLayoutID = appState.layoutStore.layouts.first?.id
        }

        setupStatusItem()

        // Prompt for accessibility and start snapping once granted
        let alreadyGranted = PermissionService.shared.requestAccessibilityIfNeeded()
        if alreadyGranted && appState.isEnabled {
            WindowSnappingService.shared.start()
        } else if appState.isEnabled {
            // Poll until the user grants permission
            PermissionService.shared.waitForAccessibility { [weak self] in
                guard let self = self, self.appState.isEnabled else { return }
                WindowSnappingService.shared.start()
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let img = NSImage(systemSymbolName: "rectangle.split.3x1",
                                 accessibilityDescription: "MacLayout") {
                img.size = NSSize(width: 18, height: 18)
                img.isTemplate = true
                button.image = img
            } else {
                button.title = "ML"
            }
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let hasPermission = PermissionService.shared.isAccessibilityGranted

        // Permission warning if not granted
        if !hasPermission {
            let warningItem = NSMenuItem(title: "⚠ Accessibility Not Granted", action: #selector(requestPermission(_:)), keyEquivalent: "")
            warningItem.target = self
            menu.addItem(warningItem)
            menu.addItem(.separator())
        }

        // Enabled toggle
        let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled(_:)), keyEquivalent: "")
        enabledItem.target = self
        enabledItem.state = appState.isEnabled ? .on : .off
        menu.addItem(enabledItem)

        menu.addItem(.separator())

        // Layouts
        let headerItem = NSMenuItem(title: "Layouts", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        for layout in appState.layoutStore.layouts {
            let item = NSMenuItem(title: "  \(layout.name)", action: #selector(selectLayout(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = layout.id
            if layout.id == appState.selectedLayoutID {
                item.state = .on
            }
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let editItem = NSMenuItem(title: "Edit Layouts...", action: #selector(openEditor(_:)), keyEquivalent: "e")
        editItem.target = self
        menu.addItem(editItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit MacLayout", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    @objc private func requestPermission(_ sender: NSMenuItem) {
        PermissionService.shared.requestAccessibilityIfNeeded()
        PermissionService.shared.waitForAccessibility { [weak self] in
            guard let self = self, self.appState.isEnabled else { return }
            // Restart snapping with new permission
            WindowSnappingService.shared.stop()
            WindowSnappingService.shared.start()
        }
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        appState.isEnabled.toggle()

        if appState.isEnabled {
            if PermissionService.shared.isAccessibilityGranted {
                WindowSnappingService.shared.start()
            } else {
                PermissionService.shared.requestAccessibilityIfNeeded()
                PermissionService.shared.waitForAccessibility {
                    WindowSnappingService.shared.start()
                }
            }
        } else {
            WindowSnappingService.shared.stop()
        }
    }

    @objc private func selectLayout(_ sender: NSMenuItem) {
        guard let layoutID = sender.representedObject as? UUID else { return }
        appState.selectedLayoutID = layoutID
    }

    @objc private func openEditor(_ sender: NSMenuItem) {
        if editorWindowController == nil {
            editorWindowController = LayoutEditorWindowController()
        }
        editorWindowController?.showWindow(nil)
        editorWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
