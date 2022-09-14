public protocol GameState: Codable, Equatable {
    var entities: EntityRepository { get set }
}

public extension GameState {
    mutating func modify<C: GameComponent>(
        _ keyPath: WritableKeyPath<Self, [EntityId: C]>,
        ofEntity entityId: EntityId,
        modifyBlock: (inout C) -> Void
    ) {
        if var component = self[keyPath: keyPath][entityId] {
            modifyBlock(&component)
            self[keyPath: keyPath][entityId] = component
        } else {
            assertionFailure("Component not found \(C.self) for \(entityId)")
        }
    }
    
    mutating func modify<C1: GameComponent, C2: GameComponent>(
        _ keyPath1: WritableKeyPath<Self, [EntityId: C1]>,
        _ keyPath2: WritableKeyPath<Self, [EntityId: C2]>,
        ofEntity entityId: EntityId,
        modifyBlock: (inout C1, inout C2) -> Void
    ) {
        if var component1 = self[keyPath: keyPath1][entityId],
            var component2 = self[keyPath: keyPath2][entityId] {
            modifyBlock(&component1, &component2)
            self[keyPath: keyPath1][entityId] = component1
            self[keyPath: keyPath2][entityId] = component2
        } else {
            assertionFailure("One or more components not found \(C1.self), \(C2.self)  for \(entityId)")
        }
    }
}
