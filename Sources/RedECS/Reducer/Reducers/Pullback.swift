import Foundation

public struct Pullback<
    GlobalState: GameState,
    GlobalAction: Equatable,
    GlobalEnvironment,
    R: Reducer
> : Reducer {
    var toLocalState: WritableKeyPath<GlobalState, R.State>
    var toLocalAction: (GlobalAction) -> R.Action?
    var toGlobalAction: (R.Action) -> GlobalAction
    var toLocalEnvironment: (GlobalEnvironment) -> R.Environment
    var reducer: R
    
    public func reduce(
        state: inout GlobalState,
        action: GlobalAction,
        environment: GlobalEnvironment
    ) -> GameEffect<GlobalState, GlobalAction> {
        guard let localAction = toLocalAction(action) else { return .none }
        return reducer.reduce(
            state: &state[keyPath: toLocalState],
            action: localAction,
            environment: toLocalEnvironment(environment)
        )
        .map(stateTransform: toLocalState, actionTransform: toGlobalAction)
    }
    
    public func reduce(
        state: inout GlobalState,
        delta: Double,
        environment: GlobalEnvironment
    ) -> GameEffect<GlobalState, GlobalAction> {
        reducer.reduce(
            state: &state[keyPath: toLocalState],
            delta: delta,
            environment: toLocalEnvironment(environment)
        )
        .map(stateTransform: toLocalState, actionTransform: toGlobalAction)
    }
    
    public func reduce(
        state: inout GlobalState,
        entityEvent: EntityEvent,
        environment: GlobalEnvironment
    ) {
        reducer.reduce(
            state: &state[keyPath: toLocalState],
            entityEvent: entityEvent,
            environment: toLocalEnvironment(environment)
        )
    }
}

public extension Reducer {
    func pullback<
        GlobalState,
        GlobalAction,
        GlobalEnvironment
    >(
        toLocalState: WritableKeyPath<GlobalState, State>,
        toLocalAction: @escaping (GlobalAction) -> Action?,
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

public extension Reducer where Environment == Void  {
    func pullback<
        GlobalState,
        GlobalAction,
        GlobalEnvironment
    >(
        toLocalState: WritableKeyPath<GlobalState, State>,
        toLocalAction: @escaping (GlobalAction) -> Action?,
        toGlobalAction: @escaping (Action) -> GlobalAction
    ) -> Pullback<GlobalState, GlobalAction, GlobalEnvironment, Self> {
        return Pullback(
            toLocalState: toLocalState,
            toLocalAction: toLocalAction,
            toGlobalAction: toGlobalAction,
            toLocalEnvironment: { _ in () },
            reducer: self
        )
    }
}

public extension Reducer where Action == Never {
    func pullback<
        GlobalState,
        GlobalAction,
        GlobalEnvironment
    >(
        toLocalState: WritableKeyPath<GlobalState, State>,
        toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> Pullback<GlobalState, GlobalAction, GlobalEnvironment, Self> {
        return Pullback(
            toLocalState: toLocalState,
            toLocalAction: { _ in nil },
            toGlobalAction: { _ -> GlobalAction in },
            toLocalEnvironment: toLocalEnvironment,
            reducer: self
        )
    }
}

public extension Reducer where Action == Never, Environment == Void {
    func pullback<
        GlobalState,
        GlobalAction,
        GlobalEnvironment
    >(
        toLocalState: WritableKeyPath<GlobalState, State>
    ) -> Pullback<GlobalState, GlobalAction, GlobalEnvironment, Self> {
        return Pullback(
            toLocalState: toLocalState,
            toLocalAction: { _ in nil },
            toGlobalAction: { _ -> GlobalAction in },
            toLocalEnvironment: { _ in () },
            reducer: self
        )
    }
}

public extension Reducer {
    func pullback<
        GlobalState,
        GlobalAction,
        GlobalEnvironment
    >(
        toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment
    ) -> Pullback<GlobalState, GlobalAction, GlobalEnvironment, Self> where Action == GlobalAction, State == GlobalState {
        return Pullback(
            toLocalState: \.self,
            toLocalAction: { $0 },
            toGlobalAction: { $0 },
            toLocalEnvironment: toLocalEnvironment,
            reducer: self
        )
    }
}

public extension Reducer where Action == Never {
    func pullback<
        GlobalState,
        GlobalAction
    >(
        toLocalState: WritableKeyPath<GlobalState, State>
    ) -> Pullback<GlobalState, GlobalAction, Environment, Self>
    {
        return Pullback(
            toLocalState: toLocalState,
            toLocalAction: { _ in nil },
            toGlobalAction: { _ -> GlobalAction in },
            toLocalEnvironment: { $0 },
            reducer: self
        )
    }
}

public extension Reducer where Action == Never {
    func pullback<GlobalAction>() -> Pullback<State, GlobalAction, Environment, Self>
    {
        return Pullback(
            toLocalState: \.self,
            toLocalAction: { _ in nil },
            toGlobalAction: { _ -> GlobalAction in },
            toLocalEnvironment: { $0 },
            reducer: self
        )
    }
}


public extension Reducer where Environment == Void {
    func pullback<
        GlobalState,
        GlobalEnvironment>(
        toLocalState: WritableKeyPath<GlobalState, State>
    ) -> Pullback<GlobalState, Action, GlobalEnvironment, Self>
    {
        return Pullback(
            toLocalState: toLocalState,
            toLocalAction: { $0 },
            toGlobalAction: { $0 },
            toLocalEnvironment: { _ in () },
            reducer: self
        )
    }
}
