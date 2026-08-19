public final class GameStore<R: Reducer> where R.State: OperationStoringGameState, R.State.GameAction == R.Action {
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
        assert(delta > 0, "Delta should be greater than 0")
        let effect = reducer.reduce(state: &state, delta: delta, environment: environment)
        handleEffect(effect)
    }

    public func sendAction(_ action: R.Action) {
//        print("[♦️] \(action)")
        var remainingAwaits: [PendingGameEffect<R.State, R.Action>] = []
        var completedEffects: [GameEffect<R.State, R.Action>] = []
        for var pending in awaitingEffects {
            if pending.evaluateCompleteness(action) {
                completedEffects.append(pending.effect)
            } else {
                remainingAwaits.append(pending)
            }
        }
        awaitingEffects = remainingAwaits
        completedEffects.forEach(handleEffect)
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
        case .operation(let entityId, let key, let operationType):
            applyOperation(entityId, key: key, operationType)
        case .removeOperation(let entityId, let key):
            removeOperation(entityId, key: key)
        case .removeAllOperations(let entityId):
            removeAllOperations(entityId)
        case .zip(let effects):
            effects.forEach(handleEffect)
        case .deferred(let promise):
            promise.onDone { [weak self] effect in
                self?.handleEffect(effect)
            }
        case .waitFor(let pendingEffect):
            if pendingEffect.isComplete {
                handleEffect(pendingEffect.effect)
            } else {
                awaitingEffects.append(pendingEffect)
            }
        }
    }

    public func clearPendingEffects() {
        awaitingEffects.removeAll()
    }

    public func sendSystemAction(_ action: SystemAction<R.State>) {
        switch action {
        case .addEntity(let entityId, let tags):
            handleEffect(addEntity(entityId, tags: tags))
        case .removeEntity(let entityId):
            handleEffect(removeEntity(entityId))
        case .setParent(let entityId, let parentId):
            state.entities.setParent(of: entityId, to: parentId)
        case .addTag(let entityId, let tag):
            state.entities.addTag(tag, to: entityId)
        case .removeTag(let entityId, let tag):
            state.entities.removeTag(tag, from: entityId)
        case .addComponent(let entityId, let componentRegistration):
            assert(isComponentTypeRegistered(id: componentRegistration.id), "Attempting to add a component type that is not registered \(String(describing: componentRegistration.id))")
            componentRegistration.onAdd(entityId, &state)
//            print("[♦️]: Added Component", componentRegistration.id, "for", entityId)
        case .removeComponent(let entityId, let registeredComponentId):
//            print("[♦️]: Removed Component", registeredComponentId, "for", entityId)
            registeredComponentTypes[registeredComponentId]?.onEntityDestroyed(entityId, &state)
        case .playSound(let sound):
            guard let soundEnvironment = environment as? SoundEnvironment else {
                assertionFailure("playSound(\(sound.rawValue)) dispatched without a SoundEnvironment")
                return
            }
            soundEnvironment.soundEngine.play(sound)
        case .stopSound(let sound):
            guard let soundEnvironment = environment as? SoundEnvironment else {
                assertionFailure("stopSound(\(sound.rawValue)) dispatched without a SoundEnvironment")
                return
            }
            soundEnvironment.soundEngine.stop(sound)
        case .stopAllSounds:
            guard let soundEnvironment = environment as? SoundEnvironment else {
                assertionFailure("stopAllSounds dispatched without a SoundEnvironment")
                return
            }
            soundEnvironment.soundEngine.stopAllSounds()
        case .cancelPendingEffects:
            clearPendingEffects()
        }
    }
    
    public func perform(_ reduceBlock: (inout R.State, R.Environment) -> GameEffect<R.State, R.Action>) {
        handleEffect(reduceBlock(&state, environment))
    }

    public func addEntity(_ id: EntityId, tags: Set<String>, parentId: EntityId? = nil) -> GameEffect<R.State, R.Action> {
        state.entities.addEntity(GameEntity(id: id, tags: tags, parentId: parentId))
        return reducer.reduce(state: &state, entityEvent: .added(id), environment: environment)
    }

    private func removeEntity(_ id: EntityId) -> GameEffect<R.State, R.Action> {
        let idsToRemove = state.entities.descendants(of: id).reversed() + [id]
        let effects = idsToRemove.map { id -> GameEffect<R.State, R.Action> in
            let preRemoveEffects = reducer.reduce(state: &state, entityEvent: .willRemove(id), environment: environment)
            registeredComponentTypes.values.forEach { componentType in
                componentType.onEntityDestroyed(id, &state)
            }
            state.entities.removeEntity(id)
            return .many(
                preRemoveEffects,
                reducer.reduce(state: &state, entityEvent: .didRemove(id), environment: environment)
            )
        }
        return .many(effects)
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

extension GameStore {
    func applyOperation(_ entityId: EntityId, key: String?, _ payload: OperationType<R.State.GameAction>) {
        guard state.entities.entityIds.contains(entityId) else { return }
        let operation = payload
        var component = state.operation[entityId] ?? OperationComponent(entity: entityId)
        if let key {
            component.newOperation(name: key, operation)
        } else {
            component.newOperation(operation)
        }
        state.operation[entityId] = component
    }

    func removeOperation(_ entityId: EntityId, key: String) {
        state.operation[entityId]?.removeOperation(name: key)
    }

    func removeAllOperations(_ entityId: EntityId) {
        state.operation[entityId]?.removeAllOperations()
    }
}

public extension GameStore {
    convenience init(
        state: R.State,
        environment: R.Environment,
        reducer: R,
        registration: GameRegistration<R.State, R.Action>
    ) {
        self.init(
            state: state,
            environment: environment,
            reducer: reducer,
            registeredComponentTypes: registration.components
        )
    }
}
