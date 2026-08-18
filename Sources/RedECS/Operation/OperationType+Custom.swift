// Builders for the open half of the system. These read exactly like the built-in
// ones, so a custom operation or a lerp chains with everything else.

public extension OperationType {
    static func custom<O: OperationPayload>(_ payload: O) -> Self {
        .custom(AnyOperation<GameAction>(payload))
    }

    func custom<O: OperationPayload>(_ payload: O) -> Self {
        var component = self
        component.appendOperation(.custom(AnyOperation<GameAction>(payload)))
        return component
    }
}

public extension OperationType {
    /// Interpolate a registered value to an absolute target.
    static func lerp<Value: Lerpable>(
        _ key: LerpKey<Value>,
        to value: Value,
        duration: Double,
        timing: TimingFunction = .linear
    ) -> Self {
        .custom(LerpOperation(key: key, amount: .to(value), duration: duration, timing: timing))
    }

    /// Interpolate a registered value by an amount relative to wherever it starts.
    static func lerp<Value: Lerpable>(
        _ key: LerpKey<Value>,
        by value: Value,
        duration: Double,
        timing: TimingFunction = .linear
    ) -> Self {
        .custom(LerpOperation(key: key, amount: .by(value), duration: duration, timing: timing))
    }

    /// Assign a registered value immediately.
    static func set<Value: Lerpable>(_ key: LerpKey<Value>, to value: Value) -> Self {
        .custom(LerpOperation(key: key, amount: .to(value), duration: 0))
    }

    func lerp<Value: Lerpable>(
        _ key: LerpKey<Value>,
        to value: Value,
        duration: Double,
        timing: TimingFunction = .linear
    ) -> Self {
        var component = self
        component.appendOperation(.lerp(key, to: value, duration: duration, timing: timing))
        return component
    }

    func lerp<Value: Lerpable>(
        _ key: LerpKey<Value>,
        by value: Value,
        duration: Double,
        timing: TimingFunction = .linear
    ) -> Self {
        var component = self
        component.appendOperation(.lerp(key, by: value, duration: duration, timing: timing))
        return component
    }

    func set<Value: Lerpable>(_ key: LerpKey<Value>, to value: Value) -> Self {
        var component = self
        component.appendOperation(.set(key, to: value))
        return component
    }
}
