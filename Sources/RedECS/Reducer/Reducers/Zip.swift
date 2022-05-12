import Foundation

public struct Zip2<A: Reducer, B: Reducer>: Reducer
where A.State == B.State,
      A.Action == B.Action,
      A.Environment == B.Environment
{
    var a: A
    var b: B
    
    public init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }
    
    public func reduce(
        state: inout A.State,
        action: A.Action,
        environment: A.Environment
    ) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, action: action, environment: environment),
            b.reduce(state: &state, action: action, environment: environment)
        ])
    }
    
    public func reduce(state: inout A.State, delta: Double, environment: A.Environment) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, delta: delta, environment: environment),
            b.reduce(state: &state, delta: delta, environment: environment)
        ])
    }
    
    public func reduce(
        state: inout A.State,
        entityEvent: EntityEvent,
        environment: A.Environment
    ) {
        a.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        b.reduce(state: &state, entityEvent: entityEvent, environment: environment)
    }
}

public func + <A: Reducer, B: Reducer> (_ lhs: A, _ rhs: B) -> Zip2<A, B>
where A.State == B.State,
      A.Action == B.Action,
      A.Environment == B.Environment {
    Zip2(lhs, rhs)
}

public func zip<A: Reducer, B: Reducer>(_ a: A, _ b: B) -> Zip2<A, B> {
    Zip2(a, b)
}

public struct Zip3<A: Reducer, B: Reducer, C: Reducer>: Reducer
where A.State == B.State,
      A.Action == B.Action,
      A.Environment == B.Environment,
      A.State == C.State,
      A.Action == C.Action,
      A.Environment == C.Environment
{
    var a: A
    var b: B
    var c: C
    
    public init(_ a: A, _ b: B, _ c: C) {
        self.a = a
        self.b = b
        self.c = c
    }
    
    public func reduce(
        state: inout A.State,
        action: A.Action,
        environment: A.Environment
    ) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, action: action, environment: environment),
            b.reduce(state: &state, action: action, environment: environment),
            c.reduce(state: &state, action: action, environment: environment)
        ])
    }
    
    public func reduce(state: inout A.State, delta: Double, environment: A.Environment) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, delta: delta, environment: environment),
            b.reduce(state: &state, delta: delta, environment: environment),
            c.reduce(state: &state, delta: delta, environment: environment)
        ])
    }
    
    public func reduce(state: inout A.State, entityEvent: EntityEvent, environment: A.Environment) {
        a.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        b.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        c.reduce(state: &state, entityEvent: entityEvent, environment: environment)
    }
}

public func zip<A: Reducer, B: Reducer, C: Reducer>(_ a: A, _ b: B, _ c: C) -> Zip3<A, B, C> {
    Zip3(a, b, c)
}

public struct Zip4<A: Reducer, B: Reducer, C: Reducer, D: Reducer>: Reducer
where A.State == B.State,
      A.Action == B.Action,
      A.Environment == B.Environment,
      A.State == C.State,
      A.Action == C.Action,
      A.Environment == C.Environment,
      A.State == D.State,
      A.Action == D.Action,
      A.Environment == D.Environment
{
    var a: A
    var b: B
    var c: C
    var d: D
    
    public init(_ a: A, _ b: B, _ c: C, _ d: D) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
    }
    
    public func reduce(
        state: inout A.State,
        action: A.Action,
        environment: A.Environment
    ) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, action: action, environment: environment),
            b.reduce(state: &state, action: action, environment: environment),
            c.reduce(state: &state, action: action, environment: environment),
            d.reduce(state: &state, action: action, environment: environment)
        ])
    }
    
    public func reduce(state: inout A.State, delta: Double, environment: A.Environment) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, delta: delta, environment: environment),
            b.reduce(state: &state, delta: delta, environment: environment),
            c.reduce(state: &state, delta: delta, environment: environment),
            d.reduce(state: &state, delta: delta, environment: environment)
        ])
    }
    
    public func reduce(state: inout A.State, entityEvent: EntityEvent, environment: A.Environment) {
        a.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        b.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        c.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        d.reduce(state: &state, entityEvent: entityEvent, environment: environment)
    }
}

public func zip<
    A: Reducer,
    B: Reducer,
    C: Reducer,
    D: Reducer
>(_ a: A, _ b: B, _ c: C, _ d: D) -> Zip4<A, B, C, D> {
    Zip4(a, b, c, d)
}

public struct Zip5<A: Reducer, B: Reducer, C: Reducer, D: Reducer, E: Reducer>: Reducer
where A.State == B.State,
      A.Action == B.Action,
      A.Environment == B.Environment,
      A.State == C.State,
      A.Action == C.Action,
      A.Environment == C.Environment,
      A.State == D.State,
      A.Action == D.Action,
      A.Environment == D.Environment,
      A.State == E.State,
      A.Action == E.Action,
      A.Environment == E.Environment
{
    var a: A
    var b: B
    var c: C
    var d: D
    var e: E
    
    public init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.e = e
    }
    
    public func reduce(
        state: inout A.State,
        action: A.Action,
        environment: A.Environment
    ) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, action: action, environment: environment),
            b.reduce(state: &state, action: action, environment: environment),
            c.reduce(state: &state, action: action, environment: environment),
            d.reduce(state: &state, action: action, environment: environment),
            e.reduce(state: &state, action: action, environment: environment)
        ])
    }
    
    public func reduce(state: inout A.State, delta: Double, environment: A.Environment) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, delta: delta, environment: environment),
            b.reduce(state: &state, delta: delta, environment: environment),
            c.reduce(state: &state, delta: delta, environment: environment),
            d.reduce(state: &state, delta: delta, environment: environment),
            e.reduce(state: &state, delta: delta, environment: environment)
        ])
    }
    
    public func reduce(state: inout A.State, entityEvent: EntityEvent, environment: A.Environment) {
        a.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        b.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        c.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        d.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        e.reduce(state: &state, entityEvent: entityEvent, environment: environment)
    }
}

public func zip<
    A: Reducer,
    B: Reducer,
    C: Reducer,
    D: Reducer,
    E: Reducer
>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Zip5<A, B, C, D, E> {
    Zip5(a, b, c, d, e)
}

public struct Zip6<A: Reducer, B: Reducer, C: Reducer, D: Reducer, E: Reducer, F: Reducer>: Reducer
where A.State == B.State,
      A.Action == B.Action,
      A.Environment == B.Environment,
      A.State == C.State,
      A.Action == C.Action,
      A.Environment == C.Environment,
      A.State == D.State,
      A.Action == D.Action,
      A.Environment == D.Environment,
      A.State == E.State,
      A.Action == E.Action,
      A.Environment == E.Environment,
      A.State == F.State,
      A.Action == F.Action,
      A.Environment == F.Environment
{
    var a: A
    var b: B
    var c: C
    var d: D
    var e: E
    var f: F
    
    public init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.e = e
        self.f = f
    }
    
    public func reduce(
        state: inout A.State,
        action: A.Action,
        environment: A.Environment
    ) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, action: action, environment: environment),
            b.reduce(state: &state, action: action, environment: environment),
            c.reduce(state: &state, action: action, environment: environment),
            d.reduce(state: &state, action: action, environment: environment),
            e.reduce(state: &state, action: action, environment: environment),
            f.reduce(state: &state, action: action, environment: environment),
        ])
    }
    
    public func reduce(state: inout A.State, delta: Double, environment: A.Environment) -> GameEffect<A.State, A.Action> {
        .many([
            a.reduce(state: &state, delta: delta, environment: environment),
            b.reduce(state: &state, delta: delta, environment: environment),
            c.reduce(state: &state, delta: delta, environment: environment),
            d.reduce(state: &state, delta: delta, environment: environment),
            e.reduce(state: &state, delta: delta, environment: environment),
            f.reduce(state: &state, delta: delta, environment: environment),
        ])
    }
    
    public func reduce(state: inout A.State, entityEvent: EntityEvent, environment: A.Environment) {
        a.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        b.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        c.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        d.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        e.reduce(state: &state, entityEvent: entityEvent, environment: environment)
        f.reduce(state: &state, entityEvent: entityEvent, environment: environment)
    }
}

public func zip<
    A: Reducer,
    B: Reducer,
    C: Reducer,
    D: Reducer,
    E: Reducer,
    F: Reducer
>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Zip6<A, B, C, D, E, F> {
    Zip6(a, b, c, d, e, f)
}
