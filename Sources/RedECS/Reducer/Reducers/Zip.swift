public struct Zip<A: Reducer, B: Reducer>: Reducer
where A.State == B.State,
      A.Action == B.Action,
      A.Environment == B.Environment
{
    let a: A
    let b: B

    public init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }

    public func reduce(
        state: inout A.State,
        action: A.Action,
        environment: A.Environment
    ) -> GameEffect<A.State, A.Action> {
        .many(
            a.reduce(state: &state, action: action, environment: environment),
            b.reduce(state: &state, action: action, environment: environment)
        )
    }

    public func reduce(
        state: inout A.State,
        delta: Double,
        environment: A.Environment
    ) -> GameEffect<A.State, A.Action> {
        .many(
            a.reduce(state: &state, delta: delta, environment: environment),
            b.reduce(state: &state, delta: delta, environment: environment)
        )
    }

    public func reduce(
        state: inout A.State,
        entityEvent: EntityEvent,
        environment: A.Environment
    ) -> GameEffect<A.State, A.Action> {
        .many(
            a.reduce(state: &state, entityEvent: entityEvent, environment: environment),
            b.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        )
    }
}

public func + <A: Reducer, B: Reducer>(_ lhs: A, _ rhs: B) -> Zip<A, B> {
    Zip(lhs, rhs)
}

public func zip<A: Reducer, B: Reducer>(_ a: A, _ b: B) -> Zip<A, B> {
    Zip(a, b)
}

public func zip<A: Reducer, B: Reducer, C: Reducer>(_ a: A, _ b: B, _ c: C) -> Zip<Zip<A, B>, C> {
    zip(zip(a, b), c)
}

public func zip<A: Reducer, B: Reducer, C: Reducer, D: Reducer>(_ a: A, _ b: B, _ c: C, _ d: D) -> Zip<Zip<Zip<A, B>, C>, D> {
    zip(zip(a, b, c), d)
}

public func zip<A: Reducer, B: Reducer, C: Reducer, D: Reducer, E: Reducer>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Zip<Zip<Zip<Zip<A, B>, C>, D>, E> {
    zip(zip(a, b, c, d), e)
}

public func zip<A: Reducer, B: Reducer, C: Reducer, D: Reducer, E: Reducer, F: Reducer>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Zip<Zip<Zip<Zip<Zip<A, B>, C>, D>, E>, F> {
    zip(zip(a, b, c, d, e), f)
}

public func zip<A: Reducer, B: Reducer, C: Reducer, D: Reducer, E: Reducer, F: Reducer, G: Reducer>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) -> Zip<Zip<Zip<Zip<Zip<Zip<A, B>, C>, D>, E>, F>, G> {
    zip(zip(a, b, c, d, e, f), g)
}

public func zip<A: Reducer, B: Reducer, C: Reducer, D: Reducer, E: Reducer, F: Reducer, G: Reducer, H: Reducer>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H) -> Zip<Zip<Zip<Zip<Zip<Zip<Zip<A, B>, C>, D>, E>, F>, G>, H> {
    zip(zip(a, b, c, d, e, f, g), h)
}
