public protocol Reducer {
    associatedtype State: GameState
    associatedtype Action: Equatable
    associatedtype Environment

    func reduce(state: inout State, delta: Double, environment: Environment) -> GameEffect<State, Action>
    func reduce(state: inout State, action: Action, environment: Environment) -> GameEffect<State, Action>
    func reduce(state: inout State, entityEvent: EntityEvent, environment: Environment) -> GameEffect<State, Action>
}

public extension Reducer {
    func reduce(state: inout State, entityEvent: EntityEvent, environment: Environment) -> GameEffect<State, Action> {
        return .none
    }
}


public extension Reducer where Action == Never {
    func reduce(state: inout State, action: Action, environment: Environment) -> GameEffect<State, Action> {

    }
}
