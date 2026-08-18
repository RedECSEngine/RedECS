public struct GameRegistration<Root: GameState, GameAction: Equatable & Codable> {
    public private(set) var components: Set<RegisteredComponentType<Root>> = []
    public private(set) var decoderTable = OperationDecoderTable()

    typealias Runner = (inout AnyOperation<GameAction>, EntityId, inout Root, Double) -> GameEffect<Root, GameAction>
    var runners: [OperationTypeId: Runner] = [:]

    public init() {}

    public func component<C: GameComponent>(
        _ keyPath: WritableKeyPath<Root, [EntityId: C]>
    ) -> Self {
        var copy = self
        copy.components.insert(RegisteredComponentType(keyPath: keyPath))
        return copy
    }

    public func component<C: OperationSupportingComponent>(
        _ keyPath: WritableKeyPath<Root, [EntityId: C]>
    ) -> Self {
        var copy = self
        copy.components.insert(RegisteredComponentType(keyPath: keyPath))
        var binder = Binder<C>(componentPath: keyPath, registration: copy)
        C.bindOperationSupport(&binder)
        return binder.registration
    }

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

    public var registeredOperationTypeIds: Set<OperationTypeId> {
        Set(runners.keys)
    }

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
