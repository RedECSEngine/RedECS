
public struct OperationComponentContext<GameAction: Equatable & Codable>: GameState, OperationCapableGameState {
    public var entities: EntityRepository = .init()
    public var operation: [EntityId: OperationComponent<GameAction>] = [:]
    public var transform: [EntityId: TransformComponent] = [:]
    public var sprite: [EntityId : SpriteComponent] = [:]
    
    public init(
        entities: EntityRepository,
        operation: [EntityId : OperationComponent<GameAction>],
        transform: [EntityId: TransformComponent],
        sprite: [EntityId : SpriteComponent]
    ) {
        self.entities = entities
        self.operation = operation
        self.transform = transform
        self.sprite = sprite
    }
}

public struct OperationReducer<State: OperationCapableGameState>: Reducer {
    public typealias Action = State.GameAction
    public typealias Environment = Void

    let registration: GameRegistration<State, State.GameAction>

    public init(registration: GameRegistration<State, State.GameAction>) {
        self.registration = registration
    }

    public func reduce(
        state: inout State,
        action: Action,
        environment: Void
    ) -> GameEffect<State, Action> {
        .none
    }

    public func reduce(
        state: inout State,
        delta: Double,
        environment: Void
    ) -> GameEffect<State, Action> {
        var effects: [GameEffect<State, Action>] = []
        for id in Array(state.operation.keys) {
            guard let component = state.operation[id] else { continue }
            for key in Array(component.operations.keys) {
                guard var operation = state.operation[id]?.operations[key] else { continue }
                effects.append(
                    operation.run(id: id, state: &state, delta: delta, registration: registration)
                )
                if operation.isComplete {
                    state.operation[id]?.operations[key] = nil
                } else {
                    state.operation[id]?.operations[key] = operation
                }
            }
        }
        return .many(effects)
    }
}
