import Graphs

public struct EntityRepository: Equatable, Codable {
    public struct Constants {
        public static let rootTreeId = "Root"
    }

    public private(set) var entities: [EntityId: GameEntity] = [:]
    public private(set) var tags: [String: Set<EntityId>] = [:]
    /// Parent/child relationships. Rendering walks this forest, composing each
    /// entity's transform with its ancestors' and honoring `isHidden` subtrees.
    public private(set) var hierarchy: OrderedForest<EntityId> = .init()

    public init() { }

    public subscript(index: EntityId) -> GameEntity? {
        get {
            entities[index]
        }
    }

    public var entityIds: Dictionary<String, GameEntity>.Keys {
        entities.keys
    }
}

// MARK: - Entity Lifecycle

public extension EntityRepository {
    mutating func addEntity(_ e: GameEntity, under parentId: EntityId? = nil) {
        assert(entities[e.id] == nil, "adding duplicate entity \(e.id)")
        e.tags.forEach { tag in
            tags[tag, default: []].insert(e.id)
        }

        let target = parentId.flatMap { $0 == Constants.rootTreeId ? nil : $0 }
        if !hierarchy.insert(e.id, under: target) {
            assertionFailure("Failed to find parent '\(parentId ?? Constants.rootTreeId)' for entity '\(e.id)'")
            hierarchy.insert(e.id, under: nil)
        }
        entities[e.id] = e
    }

    mutating func removeEntity(_ id: EntityId) {
        let removed = hierarchy.remove(id)
        for removedId in removed.isEmpty ? [id] : removed {
            entities[removedId]?.tags.forEach { tag in
                tags[tag]?.remove(removedId)
            }
            entities[removedId] = nil
        }
    }

    /// Adds `tag` to an existing entity, keeping the reverse `tags` index in
    /// sync. No-op if the entity is unknown or already carries the tag.
    mutating func addTag(_ tag: String, to id: EntityId) {
        guard entities[id] != nil else {
            assertionFailure("adding tag '\(tag)' to unknown entity '\(id)'")
            return
        }
        entities[id]?.tags.insert(tag)
        tags[tag, default: []].insert(id)
    }

    /// Removes `tag` from an entity, keeping the reverse `tags` index in sync.
    mutating func removeTag(_ tag: String, from id: EntityId) {
        entities[id]?.tags.remove(tag)
        tags[tag]?.remove(id)
    }
}

// MARK: - Hierarchy Management

public extension EntityRepository {
    /// Reparents an entity. Passing `nil` moves it back to the root.
    mutating func setParent(of entityId: EntityId, to parentId: EntityId?) {
        let target = parentId.flatMap { $0 == Constants.rootTreeId ? nil : $0 }
        guard hierarchy.move(entityId, under: target) else {
            assertionFailure("Failed to move entity '\(entityId)' under '\(parentId ?? Constants.rootTreeId)'")
            return
        }
    }

    func parent(of entityId: EntityId) -> EntityId? {
        hierarchy.parent(of: entityId)
    }

    /// All ids in the subtree rooted at `entityId`, depth-first,
    /// not including `entityId` itself.
    func descendants(of entityId: EntityId) -> [EntityId] {
        hierarchy.descendants(of: entityId)
    }
}
