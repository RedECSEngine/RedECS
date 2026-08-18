/// A type-erased, `Codable` operation.
///
/// The box holds data only. The behaviour that runs it lives in `GameRegistration`,
/// keyed by `typeId` — which is what allows a game to add operations over its own
/// components without the engine knowing about them.
public struct AnyOperation<Action: Equatable & Codable>: Equatable {
    public let typeId: OperationTypeId
    public internal(set) var payload: any OperationPayload

    public init<O: OperationPayload>(_ payload: O) {
        // Instance-level, not static: `LerpOperation` backs one registration per key.
        self.typeId = payload.operationTypeId
        self.payload = payload
    }

    public var duration: Double { payload.duration }
    public var isComplete: Bool { payload.isComplete }
    public mutating func reset() { payload.reset() }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.typeId == rhs.typeId && lhs.payload.isEqual(to: rhs.payload)
    }
}

extension AnyOperation: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case payload
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(typeId, forKey: .type)
        try container.encode(payload, forKey: .payload)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeId = try container.decode(OperationTypeId.self, forKey: .type)
        guard let table = decoder.userInfo[.operationDecoding] as? OperationDecoderTable else {
            throw OperationCodingError.registrationNotConfigured(typeId)
        }
        guard let decode = table.decoders[typeId] else {
            throw OperationCodingError.unknownOperationType(typeId)
        }
        self.typeId = typeId
        self.payload = try decode(container.superDecoder(forKey: .payload))
    }
}

public extension AnyOperation {
    /// Re-tags the box for a different action type when an effect crosses a
    /// pullback boundary.
    ///
    /// The payload itself is carried across unchanged, which is correct because a
    /// payload emits actions from `run` rather than storing them — a custom
    /// operation must not hold an `Action`-typed stored property. That restriction
    /// is currently by convention; see the note in the PR description.
    func reboxed<NewAction: Equatable & Codable>() -> AnyOperation<NewAction> {
        AnyOperation<NewAction>(typeId: typeId, payload: payload)
    }

    internal init(typeId: OperationTypeId, payload: any OperationPayload) {
        self.typeId = typeId
        self.payload = payload
    }
}
