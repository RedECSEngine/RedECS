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
}

public func + <A: Reducer, B: Reducer> (_ lhs: A, _ rhs: B) -> Zip2<A, B>
where A.State == B.State,
      A.Action == B.Action,
      A.Environment == B.Environment {
    Zip2(lhs, rhs)
}
