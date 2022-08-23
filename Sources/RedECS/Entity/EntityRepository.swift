public struct EntityRepository: Equatable, Codable {
    public private(set) var entities: [EntityId: GameEntity] = [:]
    public private(set) var tags: [String: Set<EntityId>] = [:]
    
    public init() { }
    
    public subscript(index: EntityId) -> GameEntity? {
        get {
            entities[index]
        }
    }
    
    public var entityIds: Dictionary<String, GameEntity>.Keys {
        entities.keys
    }
    
    public mutating func addEntity(_ e: GameEntity) {
        assert(entities[e.id] == nil, "adding duplicate entity \(e.id)")
        entities[e.id] = e
        e.tags.forEach { tag in
            tags[tag, default: []].insert(e.id)
        }
    }
    
    public mutating func removeEntity(_ id: EntityId) {
//        assert(entities[id] != nil, "removing already removed entity")
        entities[id]?.tags.forEach { tag in
            tags[tag]?.remove(id)
        }
        entities[id] = nil
    }
}
