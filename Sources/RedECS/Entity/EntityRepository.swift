public struct EntityRepository: Equatable, Codable {
    public struct Constants {
        public static let rootTreeId = "Root"
    }
    
    public private(set) var entities: [EntityId: GameEntity] = [:]
    public private(set) var tags: [String: Set<EntityId>] = [:]
    /// Parent/child relationships. Rendering walks this tree, composing each
    /// entity's transform with its ancestors' and honoring `isHidden` subtrees.
    public private(set) var tree: EntityTree = .init(id: Constants.rootTreeId)
    
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
    mutating func addEntity(_ e: GameEntity) {
        assert(entities[e.id] == nil, "adding duplicate entity \(e.id)")
        var e = e
        e.tags.forEach { tag in
            tags[tag, default: []].insert(e.id)
        }
        
        var parentId = Constants.rootTreeId
        if let entityParent = e.parentId {
            parentId = entityParent
        }
        var tree = self.tree
        let result = insertEntity(e.id, intoTree: &tree, withParent: parentId)
        self.tree = tree
        assert(result, "Failed to find parent in tree '\(parentId)'")
        e.parentId = parentId
        entities[e.id] = e
    }
    
    mutating func removeEntity(_ id: EntityId) {
//        assert(entities[id] != nil, "removing already removed entity")
        entities[id]?.tags.forEach { tag in
            tags[tag]?.remove(id)
        }
        var tree = self.tree
        _ = removeEntity(id, fromTree: &tree)
        self.tree = tree
        entities[id] = nil
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

// MARK: - Tree Management

public extension EntityRepository {
    /// Reparents an entity. Passing `nil` moves it back to the root.
    mutating func setParent(of entityId: EntityId, to parentId: EntityId?) {
        var tree = self.tree
        moveEntity(entityId, toParent: parentId ?? Constants.rootTreeId, inTree: &tree)
        self.tree = tree
    }

    /// All ids in the subtree rooted at `entityId`, depth-first,
    /// not including `entityId` itself.
    func descendants(of entityId: EntityId) -> [EntityId] {
        guard let node = findNode(entityId, in: tree) else { return [] }
        var result: [EntityId] = []
        func collect(_ tree: EntityTree) {
            for child in tree.children ?? [] {
                result.append(child.id)
                collect(child)
            }
        }
        collect(node)
        return result
    }

    private func findNode(_ id: EntityId, in tree: EntityTree) -> EntityTree? {
        if tree.id == id { return tree }
        for child in tree.children ?? [] {
            if let found = findNode(id, in: child) {
                return found
            }
        }
        return nil
    }

    mutating func insertEntity(
        _ eId: EntityId,
        intoTree tree: inout EntityTree,
        withParent pId: EntityId
    ) -> Bool {
        if tree.id == pId {
            tree.addChild(EntityTree(id: eId))
            return true
        } else {
            for i in 0..<tree.childCount {
                if var children = tree.children, insertEntity(eId, intoTree: &children[i], withParent: pId) {
                    tree.children = children
                    return true
                }
            }
        }
        return false
    }
    
    mutating func moveEntity(
        _ eId: EntityId,
        toParent pId: EntityId,
        inTree tree: inout EntityTree
    ) {
        guard var e = entities[eId] else {
            assert(entities[eId] != nil, "expected entity to exist")
            return
        }
        
        let resultRemove = removeEntity(eId, fromTree: &tree)
        assert(resultRemove, "Failed to find entity in tree '\(eId)'")
        let resultInsert = insertEntity(eId, intoTree: &tree, withParent: pId)
        assert(resultInsert, "Failed to find parent in tree '\(pId)'")
        
        e.parentId = pId
        entities[eId] = e
    }
    
    mutating func removeEntity(
        _ eId: EntityId,
        fromTree tree: inout EntityTree
    ) -> Bool {
            for i in 0..<tree.childCount {
                if tree.children?[i].id == eId {
                    tree.children?.remove(at: i)
                    return true
                } else if var children = tree.children, removeEntity(eId, fromTree: &children[i]) {
                    tree.children = children
                    return true
                }
            }
        return false
    }
}
