public final class GameStore<R: Reducer> {
    public private(set) var state: R.State
    public private(set) var environment: R.Environment
    private var reducer: R
    private var registeredComponentTypes: [String: RegisteredComponentType<R.State>] = [:]
    private var awaitingEffects: [PendingGameEffect<R.State, R.Action>] = []
    
    public init(
        state: R.State,
        environment: R.Environment,
        reducer: R,
        registeredComponentTypes: Set<RegisteredComponentType<R.State>>
    ) {
        self.state = state
        self.environment = environment
        self.reducer = reducer
        self.registeredComponentTypes = registeredComponentTypes.reduce(into: [:]) { $0[$1.id] = $1 }
    }

    public func sendDelta(_ delta: Double) {
        let effect = reducer.reduce(state: &state, delta: delta, environment: environment)
        handleEffect(effect)
    }

    public func sendAction(_ action: R.Action) {
//        print("[♦️] \(action)")
        var remainingAwaits: [PendingGameEffect<R.State, R.Action>] = []
        for i in 0..<awaitingEffects.count {
            if awaitingEffects[i].evaluateCompleteness(action) {
                handleEffect(awaitingEffects[i].effect)
            } else {
                remainingAwaits.append(awaitingEffects[i])
            }
        }
        awaitingEffects = remainingAwaits
        let effect = reducer.reduce(state: &state, action: action, environment: environment)
        handleEffect(effect)
    }

    public func handleEffect(_ effect: GameEffect<R.State, R.Action>) {
        switch effect {
        case .none:
            break
        case .game(let action):
            sendAction(action)
        case .system(let action):
            sendSystemAction(action)
        case .many(let effects):
            effects.forEach(handleEffect)
        case .deferred(let promise):
            promise.onDone { [weak self] effect in
                self?.handleEffect(effect)
            }
        case .waitFor(let pendingEffect):
            awaitingEffects.append(pendingEffect)
        }
    }

    public func sendSystemAction(_ action: SystemAction<R.State>) {
        switch action {
        case .addEntity(let entityId, let tags):
            addEntity(entityId, tags: tags)
        case .removeEntity(let entityId):
            removeEntity(entityId)
        case .addComponent(let entityId, let componentRegistration):
            assert(isComponentTypeRegistered(id: componentRegistration.id), "Attempting to add a component type that is not registered \(String(describing: componentRegistration.id))")
            componentRegistration.onAdd(entityId, &state)
//            print("[♦️]: Added Component", componentRegistration.id, "for", entityId)
        case .removeComponent(let entityId, let registeredComponentId):
//            print("[♦️]: Removed Component", registeredComponentId, "for", entityId)
            registeredComponentTypes[registeredComponentId]?.onEntityDestroyed(entityId, &state)
        }
    }

    public func addEntity(_ id: EntityId, tags: Set<String>) {
        state.entities.addEntity(GameEntity(id: id, tags: tags))
        reducer.reduce(state: &state, entityEvent: .added(id), environment: environment)
    }

    private func removeEntity(_ id: EntityId) {
        registeredComponentTypes.values.forEach { componentType in
            componentType.onEntityDestroyed(id, &state)
        }
        state.entities.removeEntity(id)
        reducer.reduce(state: &state, entityEvent: .removed(id), environment: environment)
    }

    public func addComponent<C: GameComponent>(
        _ component: C,
        into keyPath: WritableKeyPath<R.State, [EntityId: C]>
    ) {
        let registration = AnyComponent<R.State>(component, into: keyPath)
        assert(isComponentTypeRegistered(id: registration.id), "Attempting to add a component type that is not registered \(String(describing: registration.id))")
        registration.onAdd(component.entity, &state)
    }

    public func removeComponent<C: GameComponent>(
        ofType type: C.Type,
        from keyPath: WritableKeyPath<R.State, [EntityId: C]>,
        forEntity entity: EntityId
    ) {
        state[keyPath: keyPath][entity] = nil
    }

    private func isComponentTypeRegistered(id: String) -> Bool {
        registeredComponentTypes[id] != nil
    }

}
