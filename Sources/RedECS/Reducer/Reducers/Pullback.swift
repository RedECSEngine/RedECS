import Foundation

public struct Pullback<
    GlobalState: GameState,
    GlobalAction,
    GlobalEnvironment: GameEnvironment,
    R: Reducer
> : Reducer {
    var toLocalState: WritableKeyPath<GlobalState, R.State>
    var toLocalAction: (GlobalAction) -> R.Action
    var toGlobalAction: (R.Action) -> GlobalAction
    var toLocalEnvironment: (GlobalEnvironment) -> R.Environment
    var reducer: R
    
    public func reduce(
        state: inout GlobalState,
        action: GlobalAction,
        environment: GlobalEnvironment
    ) -> GameEffect<GlobalState, GlobalAction> {
        reducer.reduce(
            state: &state[keyPath: toLocalState],
            action: toLocalAction(action),
            environment: toLocalEnvironment(environment)
        )
        .map(stateTransform: toLocalState, actionTransform: toGlobalAction)
    }
}

public extension Reducer {
    func pullback<
        GlobalState,
        GlobalAction,
        GlobalEnvironment
    >(
        toLocalState: WritableKeyPath<GlobalState, State>,
        toLocalAction: @escaping (GlobalAction) -> Action,
        toGlobalAction: @escaping (Action) -> GlobalAction,
        toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> Pullback<GlobalState, GlobalAction, GlobalEnvironment, Self> {
        return Pullback(
            toLocalState: toLocalState,
            toLocalAction: toLocalAction,
            toGlobalAction: toGlobalAction,
            toLocalEnvironment: toLocalEnvironment,
            reducer: self
        )
    }
}
