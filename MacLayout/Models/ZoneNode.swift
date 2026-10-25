import Foundation

enum SplitDirection: String, Codable {
    case horizontal // split top/bottom
    case vertical   // split left/right
}

indirect enum ZoneNode: Codable, Identifiable {
    case leaf(id: UUID)
    case split(id: UUID, direction: SplitDirection, ratio: Double, first: ZoneNode, second: ZoneNode)

    var id: UUID {
        switch self {
        case .leaf(let id): return id
        case .split(let id, _, _, _, _): return id
        }
    }

    /// Compute the screen rect for each leaf zone given a containing rect and gap size
    func resolveRects(in rect: CGRect, gap: CGFloat = 8) -> [(UUID, CGRect)] {
        switch self {
        case .leaf(let id):
            return [(id, rect)]

        case .split(_, let direction, let ratio, let first, let second):
            let (firstRect, secondRect) = splitRect(rect, direction: direction, ratio: ratio, gap: gap)
            return first.resolveRects(in: firstRect, gap: gap) + second.resolveRects(in: secondRect, gap: gap)
        }
    }

    /// Find the leaf zone whose rect contains the given point
    func zoneAt(point: CGPoint, in rect: CGRect, gap: CGFloat = 8) -> UUID? {
        for (id, zoneRect) in resolveRects(in: rect, gap: gap) {
            if zoneRect.contains(point) {
                return id
            }
        }
        return nil
    }

    private func splitRect(_ rect: CGRect, direction: SplitDirection, ratio: Double, gap: CGFloat) -> (CGRect, CGRect) {
        let halfGap = gap / 2
        switch direction {
        case .vertical:
            let splitX = rect.origin.x + rect.width * ratio
            let first = CGRect(x: rect.origin.x, y: rect.origin.y,
                              width: splitX - rect.origin.x - halfGap,
                              height: rect.height)
            let second = CGRect(x: splitX + halfGap, y: rect.origin.y,
                               width: rect.maxX - splitX - halfGap,
                               height: rect.height)
            return (first, second)

        case .horizontal:
            let splitY = rect.origin.y + rect.height * ratio
            let first = CGRect(x: rect.origin.x, y: rect.origin.y,
                              width: rect.width,
                              height: splitY - rect.origin.y - halfGap)
            let second = CGRect(x: rect.origin.x, y: splitY + halfGap,
                               width: rect.width,
                               height: rect.maxY - splitY - halfGap)
            return (first, second)
        }
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, id, direction, ratio, first, second
    }

    private enum NodeType: String, Codable {
        case leaf, split
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .leaf(let id):
            try container.encode(NodeType.leaf, forKey: .type)
            try container.encode(id, forKey: .id)
        case .split(let id, let direction, let ratio, let first, let second):
            try container.encode(NodeType.split, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(direction, forKey: .direction)
            try container.encode(ratio, forKey: .ratio)
            try container.encode(first, forKey: .first)
            try container.encode(second, forKey: .second)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(NodeType.self, forKey: .type)
        switch type {
        case .leaf:
            let id = try container.decode(UUID.self, forKey: .id)
            self = .leaf(id: id)
        case .split:
            let id = try container.decode(UUID.self, forKey: .id)
            let direction = try container.decode(SplitDirection.self, forKey: .direction)
            let ratio = try container.decode(Double.self, forKey: .ratio)
            let first = try container.decode(ZoneNode.self, forKey: .first)
            let second = try container.decode(ZoneNode.self, forKey: .second)
            self = .split(id: id, direction: direction, ratio: ratio, first: first, second: second)
        }
    }

    // MARK: - Mutation helpers

    /// Split a leaf node into two children
    func splitLeaf(leafID: UUID, direction: SplitDirection) -> ZoneNode {
        switch self {
        case .leaf(let id) where id == leafID:
            return .split(id: UUID(), direction: direction, ratio: 0.5,
                         first: .leaf(id: UUID()), second: .leaf(id: UUID()))
        case .leaf:
            return self
        case .split(let id, let dir, let ratio, let first, let second):
            return .split(id: id, direction: dir, ratio: ratio,
                         first: first.splitLeaf(leafID: leafID, direction: direction),
                         second: second.splitLeaf(leafID: leafID, direction: direction))
        }
    }

    /// Remove a zone by replacing its parent split with its sibling
    func removeZone(zoneID: UUID) -> ZoneNode? {
        switch self {
        case .leaf:
            return self
        case .split(let id, let dir, let ratio, let first, let second):
            // If either child is the target leaf, return the other child
            if case .leaf(let fid) = first, fid == zoneID {
                return second
            }
            if case .leaf(let sid) = second, sid == zoneID {
                return first
            }
            // Recurse
            let newFirst = first.removeZone(zoneID: zoneID)
            let newSecond = second.removeZone(zoneID: zoneID)
            if let f = newFirst, let s = newSecond {
                return .split(id: id, direction: dir, ratio: ratio, first: f, second: s)
            }
            return newFirst ?? newSecond
        }
    }

    /// Update the ratio of a split node
    func updateRatio(splitID: UUID, newRatio: Double) -> ZoneNode {
        switch self {
        case .leaf:
            return self
        case .split(let id, let dir, let ratio, let first, let second):
            let r = id == splitID ? max(0.1, min(0.9, newRatio)) : ratio
            return .split(id: id, direction: dir, ratio: r,
                         first: first.updateRatio(splitID: splitID, newRatio: newRatio),
                         second: second.updateRatio(splitID: splitID, newRatio: newRatio))
        }
    }

    /// Count total leaf zones
    var leafCount: Int {
        switch self {
        case .leaf: return 1
        case .split(_, _, _, let first, let second): return first.leafCount + second.leafCount
        }
    }
}
