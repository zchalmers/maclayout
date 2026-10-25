import Foundation

struct Layout: Codable, Identifiable {
    let id: UUID
    var name: String
    var root: ZoneNode

    init(id: UUID = UUID(), name: String, root: ZoneNode) {
        self.id = id
        self.name = name
        self.root = root
    }

    // MARK: - Default Layouts

    static var halves: Layout {
        Layout(name: "Halves", root:
            .split(id: UUID(), direction: .vertical, ratio: 0.5,
                   first: .leaf(id: UUID()), second: .leaf(id: UUID()))
        )
    }

    static var thirds: Layout {
        Layout(name: "Thirds", root:
            .split(id: UUID(), direction: .vertical, ratio: 0.333,
                   first: .leaf(id: UUID()),
                   second: .split(id: UUID(), direction: .vertical, ratio: 0.5,
                                  first: .leaf(id: UUID()), second: .leaf(id: UUID())))
        )
    }

    static var quadrants: Layout {
        Layout(name: "Quadrants", root:
            .split(id: UUID(), direction: .vertical, ratio: 0.5,
                   first: .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                                 first: .leaf(id: UUID()), second: .leaf(id: UUID())),
                   second: .split(id: UUID(), direction: .horizontal, ratio: 0.5,
                                  first: .leaf(id: UUID()), second: .leaf(id: UUID())))
        )
    }
}
