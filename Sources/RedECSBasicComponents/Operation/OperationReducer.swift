import RedECS

public struct OperationComponentContext<GameAction: Equatable & Codable>: GameState, OperationCapable {
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
        state.operation.forEach { (id, operation) in
            guard var actionType = operation.type else {
                state.operation[id] = nil
                return
            }
            
            let effect = actionType.run(id: id, state: &state.basicOperationComponentState, delta: delta)
            effects.append(effect.map(
                stateTransform: \.basicOperationComponentState,
                actionTransform: { $0 }))
            
            if actionType.isComplete == true {
                state.operation[id] = nil
            } else {
                state.operation[id] = OperationComponent(entity: id, type: actionType)
            }
        }
        return .many(effects)
    }
}
