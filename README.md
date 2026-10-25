# MacLayout

MacLayout is a macOS menu-bar utility for placing dragged windows into user-defined screen zones.

The app provides a small alternative to fixed window tiling presets. You create layouts by recursively splitting a canvas into horizontal or vertical zones, choose one from the menu bar, then hold Shift while dragging a window to show the zones. Releasing the mouse over a zone moves and resizes the frontmost window to that zone.

## Architecture

The app starts as an accessory `NSApplication` with an AppKit status-item menu and a shared observable application state. A SwiftUI editor represents each layout as a recursive `ZoneNode` tree and persists layouts as JSON in Application Support. Drag detection, Accessibility access, and window placement are separate services. AppKit overlay panels render resolved zone rectangles on the active display while a drag is in progress.

## Notable engineering decisions

- Layouts use a recursive Codable tree of leaves and split nodes, so nested asymmetric arrangements do not need a separate grid model.
- Zone rectangles are resolved from the tree at runtime with an eight-point gap, making one layout work across display sizes.
- The editor updates split ratios through bindings and clamps them between 0.1 and 0.9.
- A listen-only Core Graphics event tap handles drag and modifier events, with global `NSEvent` monitors as a fallback when the tap cannot be created.
- Overlay panels are keyed by display ID, ignore mouse events, join all Spaces, and are recreated when a display frame changes.
- Accessibility window positions are handled in Quartz top-left coordinates, with explicit conversions at AppKit boundaries.

## Stack

- Swift 5
- SwiftUI
- AppKit and Cocoa
- Core Graphics event taps
- macOS Accessibility APIs
- Xcode project targeting macOS 14.0

## Running locally

Open `MacLayout.xcodeproj` in Xcode and run the `MacLayout` target, or build it from a terminal on macOS:

```sh
xcodebuild -project MacLayout.xcodeproj -scheme MacLayout -configuration Debug build
```

The app needs Accessibility permission in System Settings to observe window drags and move or resize other applications' windows.
