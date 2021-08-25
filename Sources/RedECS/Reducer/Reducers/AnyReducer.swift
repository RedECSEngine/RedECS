import Foundation

public struct AnyReducer<State: GameState, Action: Equatable, Environment>: Reducer {
    
    var reduceDelta: (inout State, Double, Environment) -> GameEffect<State, Action>
    var reduceAction: (inout State, Action, Environment) -> GameEffect<State, Action>
    
    public init(
        _ reduceDelta: @escaping (inout State, Double, Environment) -> GameEffect<State, Action>,
        _ reduceAction: @escaping (inout State, Action, Environment) -> GameEffect<State, Action>
    ) {
        self.reduceDelta = reduceDelta
        self.reduceAction = reduceAction
    }
    
    public init<R: Reducer>(_ reducer: R)
    where R.State == State,
          R.Action == Action,
          R.Environment == Environment
    {
        self.reduceDelta = reducer.reduce(state:delta:environment:)
        self.reduceAction = reducer.reduce(state:action:environment:)
    }
    
    public static var noop: Self {
        AnyReducer({ _, _, _ in .none }, { _, _, _ in .none })
    }
    
    public func reduce(state: inout State, delta: Double, environment: Environment) -> GameEffect<State, Action> {
        reduceDelta(&state, delta, environment)
    }
    
    public func reduce(state: inout State, action: Action, environment: Environment) -> GameEffect<State, Action> {
        reduceAction(&state, action, environment)
    }
}

public extension Reducer {
    func eraseToAnyReducer() -> AnyReducer<State, Action, Environment> {
        AnyReducer(self)
    }
}
