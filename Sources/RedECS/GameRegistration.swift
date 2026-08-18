/// Everything the store needs to know about a game's components and operations.
///
/// A game builds one of these and hands it to `GameStore`. Registering a component
/// is normally the only thing written: teardown, animatable values, component-scoped
/// operations and their decoding all follow from that single line.
public struct GameRegistration<Root: GameState, GameAction: Equatable & Codable> {
    /// Reuses the existing component-teardown registration the store already takes.
    public private(set) var components: Set<RegisteredComponentType<Root>> = []
    /// Handed to a `JSONDecoder` via `userInfo[.operationDecoding]`.
    public private(set) var decoderTable = OperationDecoderTable()

    typealias Runner = (inout AnyOperation<GameAction>, EntityId, inout Root, Double) -> GameEffect<Root, GameAction>
    var runners: [OperationTypeId: Runner] = [:]

    public init() {}

    // MARK: - Components

    /// A component with no declared operation support: teardown only.
    public func component<C: GameComponent>(
        _ keyPath: WritableKeyPath<Root, [EntityId: C]>
    ) -> Self {
        var copy = self
        copy.components.insert(RegisteredComponentType(keyPath: keyPath))
        return copy
    }

    /// A component that declares its own support. Chosen automatically by overload
    /// resolution — the call site is identical either way.
    public func component<C: OperationSupportingComponent>(
        _ keyPath: WritableKeyPath<Root, [EntityId: C]>
    ) -> Self {
        var copy = self
        copy.components.insert(RegisteredComponentType(keyPath: keyPath))
        var binder = Binder<C>(componentPath: keyPath, registration: copy)
        C.bindOperationSupport(&binder)
        return binder.registration
    }

    // MARK: - Operations spanning several components

    /// Escape hatch for an operation that needs more than one component. Declare it
    /// on an extension constrained to the capability protocols it requires, so a
    /// state missing one fails to build at the registration call.
    public func operation<O: OperationPayload>(
        _ type: O.Type,
        run: @escaping (inout O, EntityId, inout Root, Double) -> GameEffect<Root, GameAction>
    ) -> Self {
        var copy = self
        copy.decoderTable.insert(O.self, for: O.operationTypeId)
        copy.runners[O.operationTypeId] = { box, id, state, delta in
            guard var operation = box.payload as? O else {
                assertionFailure("Operation '\(box.typeId)' registered for \(O.self) but boxed \(Swift.type(of: box.payload))")
                return .none
            }
            let effect = run(&operation, id, &state, delta)
            box.payload = operation
            return effect
        }
        return copy
    }

    // MARK: - Running

    /// Dispatches a boxed operation to the behaviour its registration supplied.
    public func run(
        _ operation: inout AnyOperation<GameAction>,
        id: EntityId,
        state: inout Root,
        delta: Double
    ) -> GameEffect<Root, GameAction> {
        guard let runner = runners[operation.typeId] else {
            assertionFailure("No registration provides operation '\(operation.typeId)'")
            return .none
        }
        return runner(&operation, id, &state, delta)
    }

    /// Type ids this registration can both decode and run.
    public var registeredOperationTypeIds: Set<OperationTypeId> {
        Set(runners.keys)
    }

    // MARK: - Binding

    private mutating func bindLerp<Value: Lerpable>(
        _ key: LerpKey<Value>,
        get: @escaping (EntityId, Root) -> Value?,
        set: @escaping (EntityId, Value, inout Root) -> Void
    ) {
        let typeId = key.operationTypeId
        precondition(
            runners[typeId] == nil,
            "Duplicate lerp key '\(key.id)'. Keys must be unique across all components."
        )
        decoderTable.insert(LerpOperation<Value>.self, for: typeId)
        runners[typeId] = { box, entity, state, delta in
            guard var operation = box.payload as? LerpOperation<Value> else {
                assertionFailure("Operation '\(box.typeId)' is not a LerpOperation<\(Value.self)>")
                return .none
            }
            operation.step(entity: entity, delta: delta, state: &state, get: get, set: set)
            box.payload = operation
            return .none
        }
    }

    /// Knows `Root`; the component it visits does not.
    struct Binder<C: GameComponent>: ComponentBinder {
        typealias Component = C
        typealias Action = GameAction

        let componentPath: WritableKeyPath<Root, [EntityId: C]>
        var registration: GameRegistration

        mutating func value<Value: Lerpable>(
            _ key: LerpKey<Value>,
            _ path: WritableKeyPath<C, Value>
        ) {
            let componentPath = self.componentPath
            // Annotated explicitly: a bare closure body of `s[kp][id]?[kp] = v`
            // infers `-> Void?`, which then fails to cast back to `-> Void`.
            let get: (EntityId, Root) -> Value? = { id, state in
                state[keyPath: componentPath][id]?[keyPath: path]
            }
            let set: (EntityId, Value, inout Root) -> Void = { id, value, state in
                state[keyPath: componentPath][id]?[keyPath: path] = value
            }
            registration.bindLerp(key, get: get, set: set)
        }

        mutating func operation<O: ComponentOperation>(_ type: O.Type)
        where O.Component == C, O.Action == GameAction {
            let componentPath = self.componentPath
            registration.decoderTable.insert(O.self, for: O.operationTypeId)
            registration.runners[O.operationTypeId] = { box, id, state, delta in
                guard var operation = box.payload as? O else {
                    assertionFailure("Operation '\(box.typeId)' registered for \(O.self) but boxed \(Swift.type(of: box.payload))")
                    return .none
                }
                guard var component = state[keyPath: componentPath][id] else {
                    // Component gone — nothing to act on.
                    return .none
                }
                let effect = operation.run(id: id, component: &component, delta: delta)
                state[keyPath: componentPath][id] = component
                box.payload = operation
                return effect.widened()
            }
        }
    }
}
