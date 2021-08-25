import Foundation

public struct Filter<
    R: Reducer
> : Reducer {
    var reducer: R
    var predicate: (R.State, R.Action?) -> Bool
    
    public init(reducer: R, predicate: @escaping (R.State, R.Action?) -> Bool) {
        self.reducer = reducer
        self.predicate = predicate
    }
    
    public func reduce(
        state: inout R.State,
        action: R.Action,
        environment: R.Environment
    ) -> GameEffect<R.State,  R.Action> {
        guard predicate(state, action) else { return .none }
        return reducer.reduce(
            state: &state,
            action: action,
            environment: environment
        )
    }
    
    public func reduce(
        state: inout R.State,
        delta: Double,
        environment: R.Environment
    ) -> GameEffect<R.State, R.Action> {
        guard predicate(state, nil) else { return .none }
        return reducer.reduce(
            state: &state,
            delta: delta,
            environment: environment
        )
    }
}

public extension Reducer {
    func filter(
        _ predicate: @escaping (State, Action?) -> Bool
    ) -> Filter<Self> {
        return Filter(reducer: self, predicate: predicate)
    }
}
