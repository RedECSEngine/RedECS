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
    static func lerp<Value: Lerpable>(
        _ key: LerpKey<Value>,
        to value: Value,
        duration: Double,
        timing: TimingFunction = .linear
    ) -> Self {
        .custom(LerpOperation(key: key, amount: .to(value), duration: duration, timing: timing))
    }

    static func lerp<Value: Lerpable>(
        _ key: LerpKey<Value>,
        by value: Value,
        duration: Double,
        timing: TimingFunction = .linear
    ) -> Self {
        .custom(LerpOperation(key: key, amount: .by(value), duration: duration, timing: timing))
    }

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
