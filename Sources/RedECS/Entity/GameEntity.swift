public typealias EntityId = String

public func newEntityId(prefix: String? = nil) -> EntityId {
    let prefix = prefix.map({ "\($0)-" }) ?? ""
    return prefix + "\(Int.random(in: 0...Int.max))"
}

public struct GameEntity: Hashable, Identifiable, Codable {
    public var id: EntityId
    public var parentId: EntityId?
    public var tags: Set<String>
    
    public init(
        id: EntityId,
        tags: Set<String>
    ) {
        self.id = id
        self.tags = tags
    }
}

public struct EntityTree: Hashable, Codable, Identifiable {
    public var id: EntityId
    public var children: [EntityTree]?
    
    public var childCount: Int { children?.count ?? 0 }
    
    mutating func addChild(_ c: EntityTree) {
        if children == nil {
            children = [c]
        } else {
            children?.append(c)
        }
    }
}
