/// Names one animatable value. Declared beside the component that owns it, and
/// bound to a concrete keypath by that component's `bindOperationSupport`.
///
/// Open by construction: anyone can add a key in an extension, engine or game.
public struct LerpKey<Value: Lerpable>: Codable, Equatable, Hashable, Sendable {
    public let id: String

    public init(_ id: String) {
        self.id = id
    }

    public init(from decoder: any Decoder) throws {
        id = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }

    /// The operation type id of the lerp bound to this key.
    var operationTypeId: OperationTypeId { "engine.lerp.\(id)" }
}

/// Interpolates one registered value over time.
///
/// One Swift type backs every animated value in the game; the `key` is what tells
/// them apart, both in the registry and in a save file. The payload holds no
/// accessor — reading and writing happens through the closures the component's
/// registration installed, which is where the state knowledge lives.
public struct LerpOperation<Value: Lerpable>: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.lerp" }
    public var operationTypeId: OperationTypeId { key.operationTypeId }

    public enum Amount: Codable, Equatable {
        case to(Value)
        case by(Value)
    }

    public let key: LerpKey<Value>
    public var amount: Amount
    public var duration: Double
    public var timing: TimingFunction
    /// Captured on the first tick. Codable, so a state saved mid-lerp resumes on
    /// exactly the same curve rather than restarting from wherever it now sits.
    public var start: Value?
    public var currentTime: Double

    public var isComplete: Bool { currentTime >= duration }

    public init(
        key: LerpKey<Value>,
        amount: Amount,
        duration: Double,
        timing: TimingFunction = .linear,
        start: Value? = nil,
        currentTime: Double = 0
    ) {
        self.key = key
        self.amount = amount
        self.duration = duration
        self.timing = timing
        self.start = start
        self.currentTime = currentTime
    }

    public mutating func reset() {
        currentTime = 0
        start = nil
    }

    /// Advances one tick against whatever state the accessors were built for.
    mutating func step<S>(
        entity: EntityId,
        delta: Double,
        state: inout S,
        get: (EntityId, S) -> Value?,
        set: (EntityId, Value, inout S) -> Void
    ) {
        if start == nil {
            start = get(entity, state)
        }
        guard let start else {
            // Nothing to animate — the component is absent. Finish rather than spin.
            currentTime = duration
            return
        }
        currentTime = min(currentTime + delta, duration)
        let t = duration <= 0 ? 1 : timing(currentTime / duration)
        let end: Value
        switch amount {
        case .to(let value): end = value
        case .by(let value): end = Value.offset(start, by: value)
        }
        set(entity, Value.lerp(start, end, t), &state)
    }
}
