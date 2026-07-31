public indirect enum GameEffect<State: GameState, LogicAction: Equatable & Codable> {
    case system(SystemAction<State>)
    case game(LogicAction)
    case operation(EntityId, key: String?, OperationType<LogicAction>)
    case removeOperation(EntityId, key: String)
    case removeAllOperations(EntityId)
    case waitFor(PendingGameEffect<State, LogicAction>)
    /// Several effects, run in order. Stores exactly what it is given —
    /// prefer the `many(_:)` factories, which normalise first.
    case zip([Self])
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
        case .operation(let entityId, let key, let operationType):
            return .operation(entityId, key: key, operationType.map(actionTransform))
        case .removeOperation(let entityId, let key):
            return .removeOperation(entityId, key: key)
        case .removeAllOperations(let entityId):
            return .removeAllOperations(entityId)
        case .zip(let effects):
            // Structure-preserving: mapping cannot introduce `.none` or
            // nesting, so an already-normalised tree stays normalised and
            // there is nothing for `many(_:)` to do here.
            return .zip(effects.map { $0.map(stateTransform: stateTransform, actionTransform: actionTransform) })
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
    static func operation(_ entityId: EntityId, _ operation: OperationType<LogicAction>) -> Self {
        .operation(entityId, key: nil, operation)
    }
}

// MARK: - Normalising combinators

/// `many(_:)` is the combining entry point. It produces the same run order as
/// the raw `.zip` case but strips the shapes that cost work without doing
/// anything: an all-`.none` group collapses to `.none`, a lone survivor is
/// returned bare, nested groups are flattened to one level, and an already
/// satisfied `waitFor` is unwrapped to the effect it was guarding.
///
/// That matters because those shapes are not free. `GameStore.handleEffect`
/// walks every node, and `map` rebuilds an array per `.zip` node on each
/// pullback layer an effect passes through, so a group of nothing still costs
/// an allocation per layer.
///
/// The fixed-arity overloads exist so callers combining a known number of
/// effects never build an intermediate array — the common all-`.none` case
/// allocates nothing at all.
public extension GameEffect {
    /// True when this effect would change shape under normalisation.
    @usableFromInline
    internal var needsNormalising: Bool {
        switch self {
        case .none, .zip:
            return true
        case .waitFor(let pending):
            return pending.outstandingActions.isEmpty
        default:
            return false
        }
    }

    /// Number of real effects this contributes once normalised.
    @usableFromInline
    internal var leafCount: Int {
        switch self {
        case .none:
            return 0
        case .zip(let effects):
            var total = 0
            for effect in effects { total += effect.leafCount }
            return total
        case .waitFor(let pending) where pending.outstandingActions.isEmpty:
            return pending.effect.leafCount
        default:
            return 1
        }
    }

    /// First real effect in run order, or nil when this contributes none.
    @usableFromInline
    internal var firstLeaf: Self? {
        switch self {
        case .none:
            return nil
        case .zip(let effects):
            for effect in effects {
                if let leaf = effect.firstLeaf { return leaf }
            }
            return nil
        case .waitFor(let pending) where pending.outstandingActions.isEmpty:
            return pending.effect.firstLeaf
        default:
            return self
        }
    }

    @usableFromInline
    internal func appendLeaves(into out: inout [Self]) {
        switch self {
        case .none:
            break
        case .zip(let effects):
            for effect in effects { effect.appendLeaves(into: &out) }
        case .waitFor(let pending) where pending.outstandingActions.isEmpty:
            pending.effect.appendLeaves(into: &out)
        default:
            out.append(self)
        }
    }

    @inlinable
    static func many(_ effects: [Self]) -> Self {
        if effects.isEmpty { return .none }
        // Nothing to fix: hand the caller's array straight through.
        if !effects.contains(where: { $0.needsNormalising }) {
            return effects.count == 1 ? effects[0] : .zip(effects)
        }
        var total = 0
        for effect in effects { total += effect.leafCount }
        if total == 0 { return .none }
        if total == 1 {
            for effect in effects {
                if let leaf = effect.firstLeaf { return leaf }
            }
            return .none
        }
        var out: [Self] = []
        out.reserveCapacity(total)
        for effect in effects { effect.appendLeaves(into: &out) }
        return .zip(out)
    }

    @inlinable
    static func many(_ a: Self, _ b: Self) -> Self {
        if !a.needsNormalising, !b.needsNormalising { return .zip([a, b]) }
        let total = a.leafCount + b.leafCount
        if total == 0 { return .none }
        if total == 1 { return a.firstLeaf ?? b.firstLeaf ?? .none }
        var out: [Self] = []
        out.reserveCapacity(total)
        a.appendLeaves(into: &out)
        b.appendLeaves(into: &out)
        return .zip(out)
    }

    @inlinable
    static func many(_ a: Self, _ b: Self, _ c: Self) -> Self {
        if !a.needsNormalising, !b.needsNormalising, !c.needsNormalising {
            return .zip([a, b, c])
        }
        let total = a.leafCount + b.leafCount + c.leafCount
        if total == 0 { return .none }
        if total == 1 { return a.firstLeaf ?? b.firstLeaf ?? c.firstLeaf ?? .none }
        var out: [Self] = []
        out.reserveCapacity(total)
        a.appendLeaves(into: &out)
        b.appendLeaves(into: &out)
        c.appendLeaves(into: &out)
        return .zip(out)
    }

    @inlinable
    static func many(_ a: Self, _ b: Self, _ c: Self, _ d: Self) -> Self {
        if !a.needsNormalising, !b.needsNormalising, !c.needsNormalising, !d.needsNormalising {
            return .zip([a, b, c, d])
        }
        let total = a.leafCount + b.leafCount + c.leafCount + d.leafCount
        if total == 0 { return .none }
        if total == 1 {
            return a.firstLeaf ?? b.firstLeaf ?? c.firstLeaf ?? d.firstLeaf ?? .none
        }
        var out: [Self] = []
        out.reserveCapacity(total)
        a.appendLeaves(into: &out)
        b.appendLeaves(into: &out)
        c.appendLeaves(into: &out)
        d.appendLeaves(into: &out)
        return .zip(out)
    }

    @inlinable
    static func many(_ a: Self, _ b: Self, _ c: Self, _ d: Self, _ e: Self) -> Self {
        if !a.needsNormalising, !b.needsNormalising, !c.needsNormalising,
           !d.needsNormalising, !e.needsNormalising {
            return .zip([a, b, c, d, e])
        }
        let total = a.leafCount + b.leafCount + c.leafCount + d.leafCount + e.leafCount
        if total == 0 { return .none }
        if total == 1 {
            return a.firstLeaf ?? b.firstLeaf ?? c.firstLeaf ?? d.firstLeaf ?? e.firstLeaf ?? .none
        }
        var out: [Self] = []
        out.reserveCapacity(total)
        a.appendLeaves(into: &out)
        b.appendLeaves(into: &out)
        c.appendLeaves(into: &out)
        d.appendLeaves(into: &out)
        e.appendLeaves(into: &out)
        return .zip(out)
    }

    @inlinable
    static func many(_ a: Self, _ b: Self, _ c: Self, _ d: Self, _ e: Self, _ f: Self) -> Self {
        if !a.needsNormalising, !b.needsNormalising, !c.needsNormalising,
           !d.needsNormalising, !e.needsNormalising, !f.needsNormalising {
            return .zip([a, b, c, d, e, f])
        }
        let total = a.leafCount + b.leafCount + c.leafCount
            + d.leafCount + e.leafCount + f.leafCount
        if total == 0 { return .none }
        if total == 1 {
            return a.firstLeaf ?? b.firstLeaf ?? c.firstLeaf
                ?? d.firstLeaf ?? e.firstLeaf ?? f.firstLeaf ?? .none
        }
        var out: [Self] = []
        out.reserveCapacity(total)
        a.appendLeaves(into: &out)
        b.appendLeaves(into: &out)
        c.appendLeaves(into: &out)
        d.appendLeaves(into: &out)
        e.appendLeaves(into: &out)
        f.appendLeaves(into: &out)
        return .zip(out)
    }
}

public extension GameEffect {
    static func newEntity<C1: GameComponent>(
        _ entityId: EntityId = newEntityId(),
        tags: Set<String> = [],
        with c1KeyPath: WritableKeyPath<State, [EntityId: C1]>,
        _ modify: (inout C1) -> Void
    ) -> GameEffect<State, LogicAction> {
        var c1 = C1.init(entity: entityId)
        modify(&c1)
        return .many(
            .system(.addEntity(entityId, tags)),
            .system(.addComponent(c1, into: c1KeyPath))
        )
    }
    
    static func newEntity<C1: GameComponent, C2: GameComponent>(
        _ entityId: EntityId = newEntityId(),
        tags: Set<String> = [],
        with c1KeyPath: WritableKeyPath<State, [EntityId: C1]>,
        _ c2KeyPath: WritableKeyPath<State, [EntityId: C2]>,
        _ modify: (inout C1, inout C2) -> Void
    ) -> GameEffect<State, LogicAction> {
        var c1 = C1.init(entity: entityId)
        var c2 = C2.init(entity: entityId)
        modify(&c1, &c2)
        return .many(
            .system(.addEntity(entityId, tags)),
            .system(.addComponent(c1, into: c1KeyPath)),
            .system(.addComponent(c2, into: c2KeyPath))
        )
    }
    
    static func newEntity<
        C1: GameComponent,
        C2: GameComponent,
        C3: GameComponent
    >(
        _ entityId: EntityId = newEntityId(),
        tags: Set<String> = [],
        with c1KeyPath: WritableKeyPath<State, [EntityId: C1]>,
        _ c2KeyPath: WritableKeyPath<State, [EntityId: C2]>,
        _ c3KeyPath: WritableKeyPath<State, [EntityId: C3]>,
        _ modify: (inout C1, inout C2, inout C3) -> Void
    ) -> GameEffect<State, LogicAction> {
        var c1 = C1.init(entity: entityId)
        var c2 = C2.init(entity: entityId)
        var c3 = C3.init(entity: entityId)
        modify(&c1, &c2, &c3)
        return .many(
            .system(.addEntity(entityId, tags)),
            .system(.addComponent(c1, into: c1KeyPath)),
            .system(.addComponent(c2, into: c2KeyPath)),
            .system(.addComponent(c3, into: c3KeyPath))
        )
    }
    
    static func newEntity<
        C1: GameComponent,
        C2: GameComponent,
        C3: GameComponent,
        C4: GameComponent
    >(
        _ entityId: EntityId = newEntityId(),
        tags: Set<String> = [],
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
        return .many(
            .system(.addEntity(entityId, tags)),
            .system(.addComponent(c1, into: c1KeyPath)),
            .system(.addComponent(c2, into: c2KeyPath)),
            .system(.addComponent(c3, into: c3KeyPath)),
            .system(.addComponent(c4, into: c4KeyPath))
        )
    }
    
    static func newEntity<
        C1: GameComponent,
        C2: GameComponent,
        C3: GameComponent,
        C4: GameComponent,
        C5: GameComponent
    >(
        _ entityId: EntityId = newEntityId(),
        tags: Set<String> = [],
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
        return .many(
            .system(.addEntity(entityId, tags)),
            .system(.addComponent(c1, into: c1KeyPath)),
            .system(.addComponent(c2, into: c2KeyPath)),
            .system(.addComponent(c3, into: c3KeyPath)),
            .system(.addComponent(c4, into: c4KeyPath)),
            .system(.addComponent(c5, into: c5KeyPath))
        )
    }
}
