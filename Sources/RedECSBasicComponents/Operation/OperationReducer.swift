import RedECS

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

public struct OperationReducer<GameAction: Equatable & Codable>: Reducer {
    public func reduce(
        state: inout OperationComponentContext<GameAction>,
        action: GameAction,
        environment: ()
    ) -> GameEffect<OperationComponentContext<GameAction>, GameAction> {
        .none
    }
    
    public init() { }
    public func reduce(
        state: inout OperationComponentContext<GameAction>,
        delta: Double,
        environment: Void
    ) -> GameEffect<OperationComponentContext<GameAction>, GameAction> {
        var effects: [GameEffect<OperationComponentContext<GameAction>, GameAction>] = []
        state.operation.forEach { (id, operationComponent) in
            var operationComponent = operationComponent
            for (key, operation) in operationComponent.operations {
                var operation = operation
                let effect = operation.run(id: id, state: &state.basicOperationComponentState, delta: delta)
                effects.append(effect.map(
                    stateTransform: \.basicOperationComponentState,
                    actionTransform: { $0 }
                ))
                if operation.isComplete == true {
                    operationComponent.operations[key] = nil
                } else {
                    operationComponent.operations[key] = operation
                }
            }
            state.operation[id] = operationComponent
        }
        return .many(effects)
    }
}
