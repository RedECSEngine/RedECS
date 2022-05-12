import Foundation

public struct Throttle<
    R: Reducer
> : Reducer {
    var reducer: AnyReducer<R.State, R.Action, R.Environment>
    var minimumDuration: Double

    public init(reducer: R, minimumDuration: Double) {
        var accumulatedDelta: Double = 0
        self.reducer = AnyReducer(
            { state, delta, env in
                accumulatedDelta += delta
                guard accumulatedDelta >= minimumDuration else { return .none }
                let nextDelta = accumulatedDelta
                accumulatedDelta = 0
                return reducer.reduce(state: &state, delta: nextDelta, environment: env)
            },
            reducer.reduce(state:action:environment:),
            reducer.reduce(state:entityEvent:environment:)
        )
        self.minimumDuration = minimumDuration
    }

    public func reduce(
        state: inout R.State,
        action: R.Action,
        environment: R.Environment
    ) -> GameEffect<R.State,  R.Action> {
        reducer.reduce(
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
        reducer.reduce(
            state: &state,
            delta: delta,
            environment: environment
        )
    }
    
    public func reduce(
        state: inout R.State,
        entityEvent: EntityEvent,
        environment: R.Environment
    ) {
        reducer.reduce(
            state: &state,
            entityEvent: entityEvent,
            environment: environment
        )
    }
}

public extension Reducer {
    func throttle(
        _ minimumDuration: Double
    ) -> Throttle<Self> {
        return Throttle(reducer: self, minimumDuration: minimumDuration)
    }
}
