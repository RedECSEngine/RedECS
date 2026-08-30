public struct OperationsReducer<State: OperationCapableGameState>: Reducer {
    public init() { }

    public func reduce(
        state: inout State,
        action: State.GameAction,
        environment: Void
    ) -> GameEffect<State, State.GameAction> {
        .none
    }

    public func reduce(
        state: inout State,
        delta: Double,
        environment: Void
    ) -> GameEffect<State, State.GameAction> {
        var effects: [GameEffect<State, State.GameAction>] = []
        for (id, operationComponent) in state.operation {
            var operationComponent = operationComponent
            for (key, operation) in operationComponent.operations {
                var operation = operation
                effects.append(operation.run(id: id, state: &state, delta: delta))
                if operation.isComplete {
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
