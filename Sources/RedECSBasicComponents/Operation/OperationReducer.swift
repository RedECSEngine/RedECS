import RedECS

public struct OperationComponentContext<GameAction: Equatable & Codable>: GameState, OperationCapable {
    public var entities: EntityRepository = .init()
    public var operation: [EntityId: OperationComponent<GameAction>] = [:]
    
    public init(
        entities: EntityRepository = .init(),
        operation: [EntityId : OperationComponent<GameAction>] = [:]
    ) {
        self.entities = entities
        self.operation = operation
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
            var op = operation
            op.delta += delta
            switch op.type {
            case .wait(let amount):
                if op.delta >= amount {
                    effects.append(.system(.removeEntity(id)))
                    effects.append(.game(op.onComplete))
                }
            }
            state.operation[id] = op
        }
        return .many(effects)
    }
}
