/// Receives a component's description of what operations may do to it.
///
/// The binder is generic so that a component never has to name the game's state
/// type — `GameRegistration` supplies a binder that already knows it, and composes
/// the component keypath with whatever keypaths the component hands over.
public protocol ComponentBinder {
    associatedtype Component: GameComponent
    associatedtype Action: Equatable & Codable

    /// Expose a value for animation. Enables `.lerp(key, to:/by:)` and `.set(key, to:)`.
    mutating func value<Value: Lerpable>(
        _ key: LerpKey<Value>,
        _ path: WritableKeyPath<Component, Value>
    )

    /// Expose an operation scoped to this component.
    mutating func operation<O: ComponentOperation>(_ type: O.Type)
    where O.Component == Component, O.Action == Action
}

/// A component that describes its own operation support.
///
/// Adopting this is all it takes for `GameRegistration.component(_:)` to pick up
/// the component's animatable values and component-scoped operations — including
/// their decoding — from the one registration line the game already writes.
public protocol OperationSupportingComponent: GameComponent {
    static func bindOperationSupport<B: ComponentBinder>(_ binder: inout B) where B.Component == Self
}
