import Foundation

public struct AnyReducer<State: GameState, Action, Environment: GameEnvironment>: Reducer {
    
    var reducer: (inout State, Action, Environment) -> GameEffect<State, Action>
    
    public init(
        _ closure: @escaping (inout State, Action, Environment) -> GameEffect<State, Action>
    ) {
        self.reducer = closure
    }
    
    public init<R: Reducer>(_ reducer: R)
    where R.State == State,
          R.Action == Action,
          R.Environment == Environment
    {
        self.reducer = reducer.reduce(state:action:environment:)
    }
    
    public static var noop: Self {
        AnyReducer { _, _, _ in .none }
    }
    
    public func reduce(state: inout State, action: Action, environment: Environment) -> GameEffect<State, Action> {
        reducer(&state, action, environment)
    }
}

public extension Reducer {
    func eraseToAnyReducer() -> AnyReducer<State, Action, Environment> {
        AnyReducer(self)
    }
}
