public protocol ComponentBinder {
    associatedtype Component: GameComponent
    associatedtype Action: Equatable & Codable

    mutating func value<Value: Lerpable>(
        _ key: LerpKey<Value>,
        _ path: WritableKeyPath<Component, Value>
    )

    mutating func operation<O: ComponentOperation>(_ type: O.Type)
    where O.Component == Component, O.Action == Action
}

public protocol OperationSupportingComponent: GameComponent {
    static func bindOperationSupport<B: ComponentBinder>(_ binder: inout B) where B.Component == Self
}
