public indirect enum GameEffect<State: GameState, LogicAction: Equatable> {
    case system(SystemAction<State>)
    case game(LogicAction)
    case waitFor(PendingGameEffect<State, LogicAction>)
    case many([Self])
    case none
    
    /// This case is intended primarily for asset loading. 
    case deferred(Future<Self, Never>)

    public func map<S: GameState, A>(
        stateTransform: WritableKeyPath<S, State>,
        actionTransform: @escaping (LogicAction) -> A
    ) -> GameEffect<S, A> {
        switch self {
        case .system(let action):
            return .system(action.map(stateTransform))
        case .game(let action):
            return .game(actionTransform(action))
        case .many(let effects):
            return .many(effects.map { $0.map(stateTransform: stateTransform, actionTransform: actionTransform) })
        case .deferred(let promise):
            return .deferred(promise.map({
                $0.map(stateTransform: stateTransform, actionTransform: actionTransform)
            }))
        case .waitFor(let pendingEffect):
            return .waitFor(pendingEffect.map(stateTransform: stateTransform, actionTransform: actionTransform))
        case .none:
            return .none
        }
    }
}

public extension GameEffect {
    static func newEntity<C1: GameComponent>(
        _ entityId: EntityId = newEntityId(),
        with c1KeyPath: WritableKeyPath<State, [EntityId: C1]>,
        _ modify: (inout C1) -> Void
    ) -> GameEffect<State, LogicAction> {
        var c1 = C1.init(entity: entityId)
        modify(&c1)
        return .many([
            .system(.addEntity(entityId, [])),
            .system(.addComponent(c1, into: c1KeyPath))
        ])
    }
    
    static func newEntity<C1: GameComponent, C2: GameComponent>(
        _ entityId: EntityId = newEntityId(),
        with c1KeyPath: WritableKeyPath<State, [EntityId: C1]>,
        _ c2KeyPath: WritableKeyPath<State, [EntityId: C2]>,
        _ modify: (inout C1, inout C2) -> Void
    ) -> GameEffect<State, LogicAction> {
        var c1 = C1.init(entity: entityId)
        var c2 = C2.init(entity: entityId)
        modify(&c1, &c2)
        return .many([
            .system(.addEntity(entityId, [])),
            .system(.addComponent(c1, into: c1KeyPath)),
            .system(.addComponent(c2, into: c2KeyPath))
        ])
    }
    
    static func newEntity<
        C1: GameComponent,
        C2: GameComponent,
        C3: GameComponent
    >(
        _ entityId: EntityId = newEntityId(),
        with c1KeyPath: WritableKeyPath<State, [EntityId: C1]>,
        _ c2KeyPath: WritableKeyPath<State, [EntityId: C2]>,
        _ c3KeyPath: WritableKeyPath<State, [EntityId: C3]>,
        _ modify: (inout C1, inout C2, inout C3) -> Void
    ) -> GameEffect<State, LogicAction> {
        var c1 = C1.init(entity: entityId)
        var c2 = C2.init(entity: entityId)
        var c3 = C3.init(entity: entityId)
        modify(&c1, &c2, &c3)
        return .many([
            .system(.addEntity(entityId, [])),
            .system(.addComponent(c1, into: c1KeyPath)),
            .system(.addComponent(c2, into: c2KeyPath)),
            .system(.addComponent(c3, into: c3KeyPath))
        ])
    }
    
    static func newEntity<
        C1: GameComponent,
        C2: GameComponent,
        C3: GameComponent,
        C4: GameComponent
    >(
        _ entityId: EntityId = newEntityId(),
        with c1KeyPath: WritableKeyPath<State, [EntityId: C1]>,
        _ c2KeyPath: WritableKeyPath<State, [EntityId: C2]>,
        _ c3KeyPath: WritableKeyPath<State, [EntityId: C3]>,
        _ c4KeyPath: WritableKeyPath<State, [EntityId: C4]>,
        _ modify: (inout C1, inout C2, inout C3, inout C4) -> Void
    ) -> GameEffect<State, LogicAction> {
        var c1 = C1.init(entity: entityId)
        var c2 = C2.init(entity: entityId)
        var c3 = C3.init(entity: entityId)
        var c4 = C4.init(entity: entityId)
        modify(&c1, &c2, &c3, &c4)
        return .many([
            .system(.addEntity(entityId, [])),
            .system(.addComponent(c1, into: c1KeyPath)),
            .system(.addComponent(c2, into: c2KeyPath)),
            .system(.addComponent(c3, into: c3KeyPath)),
            .system(.addComponent(c4, into: c4KeyPath))
        ])
    }
    
    static func newEntity<
        C1: GameComponent,
        C2: GameComponent,
        C3: GameComponent,
        C4: GameComponent,
        C5: GameComponent
    >(
        _ entityId: EntityId = newEntityId(),
        with c1KeyPath: WritableKeyPath<State, [EntityId: C1]>,
        _ c2KeyPath: WritableKeyPath<State, [EntityId: C2]>,
        _ c3KeyPath: WritableKeyPath<State, [EntityId: C3]>,
        _ c4KeyPath: WritableKeyPath<State, [EntityId: C4]>,
        _ c5KeyPath: WritableKeyPath<State, [EntityId: C5]>,
        _ modify: (inout C1, inout C2, inout C3, inout C4, inout C5) -> Void
    ) -> GameEffect<State, LogicAction> {
        var c1 = C1.init(entity: entityId)
        var c2 = C2.init(entity: entityId)
        var c3 = C3.init(entity: entityId)
        var c4 = C4.init(entity: entityId)
        var c5 = C5.init(entity: entityId)
        modify(&c1, &c2, &c3, &c4, &c5)
        return .many([
            .system(.addEntity(entityId, [])),
            .system(.addComponent(c1, into: c1KeyPath)),
            .system(.addComponent(c2, into: c2KeyPath)),
            .system(.addComponent(c3, into: c3KeyPath)),
            .system(.addComponent(c4, into: c4KeyPath)),
            .system(.addComponent(c5, into: c5KeyPath))
        ])
    }
}
