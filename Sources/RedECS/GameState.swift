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
        }
    }
}
