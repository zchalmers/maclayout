import Foundation

@Observable
class LayoutStore {
    var layouts: [Layout] = []

    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("MacLayout", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("layouts.json")
    }

    func loadLayouts() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            createDefaults()
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            layouts = try JSONDecoder().decode([Layout].self, from: data)
        } catch {
            print("Failed to load layouts: \(error)")
            createDefaults()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(layouts)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save layouts: \(error)")
        }
    }

    func addLayout(_ layout: Layout) {
        layouts.append(layout)
        save()
    }

    func deleteLayout(id: UUID) {
        layouts.removeAll(where: { $0.id == id })
        save()
    }

    func updateLayout(_ layout: Layout) {
        if let index = layouts.firstIndex(where: { $0.id == layout.id }) {
            layouts[index] = layout
            save()
        }
    }

    private func createDefaults() {
        layouts = [Layout.halves, Layout.thirds, Layout.quadrants]
        save()
    }
}
