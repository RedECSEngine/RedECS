import Foundation

public final class GameStore<R: Reducer> {
    public private(set) var state: R.State
    public private(set) var environment: R.Environment
    private var reducer: R
    private var registeredComponentTypes: Set<RegisteredComponentType<R.State>> = []
    
    public init(
        state: R.State,
        environment: R.Environment,
        reducer: R,
        registeredComponentTypes: Set<RegisteredComponentType<R.State>>
    ) {
        self.state = state
        self.environment = environment
        self.reducer = reducer
        self.registeredComponentTypes = registeredComponentTypes
    }
    
    public init(
        data: Data,
        environment: R.Environment,
        reducer: R,
        registeredComponentTypes: Set<RegisteredComponentType<R.State>>
    ) throws {
        self.state = try JSONDecoder().decode(R.State.self, from: data)
        self.environment = environment
        self.reducer = reducer
        self.registeredComponentTypes = registeredComponentTypes
    }
    
    public func saveState() throws -> Data {
        try JSONEncoder().encode(state)
    }
    
    public func send(_ action: R.Action) {
        let effect = reducer.reduce(state: &state, action: action, environment: environment)
        handleEffect(effect)
    }
    
    public func handleEffect(_ effect: GameEffect<R.State, R.Action>) {
        switch effect {
        case .none:
            break
        case .logicAction(let action):
            send(action)
        case .systemAction(let action):
            sendSystemAction(action)
        case .many(let effects):
            effects.forEach(handleEffect)
        }
    }
    
    public func sendSystemAction(_ action: SystemAction<R.State>) {
        switch action {
        case .addEntity(let e):
            addEntity(e)
        case .removeEntity(let e):
            removeEntity(e)
        case .addComponent(_, let cId, let closure):
            assert(isComponentTypeRegistered(id: cId), "Attempting to add a component type that is not registered")
            closure(&state)
        case .removeComponent(_, let closure):
            closure(&state)
        }
    }
    
    private func addEntity(_ id: EntityId) {
        state.entities.insert(id)
    }
    
    private func removeEntity(_ id: EntityId) {
        state.entities.remove(id)
        registeredComponentTypes.forEach { componentType in
            componentType.onEntityDestroyed(id, &state)
        }
    }
    
    private func isComponentTypeRegistered(id: String) -> Bool {
        registeredComponentTypes.map({ $0.id }).contains(id)
    }

}
