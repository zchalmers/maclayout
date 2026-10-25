import Foundation

@Observable
class AppState {
    static let shared = AppState()

    var isEnabled: Bool = true
    var selectedLayoutID: UUID?
    let layoutStore = LayoutStore()

    var selectedLayout: Layout? {
        guard let id = selectedLayoutID else {
            return layoutStore.layouts.first
        }
        return layoutStore.layouts.first(where: { $0.id == id }) ?? layoutStore.layouts.first
    }

    private init() {}
}
