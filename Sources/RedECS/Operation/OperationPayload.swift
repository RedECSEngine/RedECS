/// The serialisable half of an operation: pure data, no state, no behaviour.
///
/// Behaviour is supplied at registration (see `GameRegistration`), which is what
/// keeps the payload free of any reference to the game's state type. That in turn
/// is what lets `GameEffect` carry operations without needing to lift them across
/// a `Pullback`.
public protocol OperationPayload: Codable, Equatable {
    /// Stable identity for the type, used as the discriminator when encoding.
    static var operationTypeId: OperationTypeId { get }

    /// Per-instance identity. Defaults to the static id, and is overridden by
    /// payloads where one Swift type backs several registrations — see
    /// `LerpOperation`, where the identity comes from the `LerpKey`.
    var operationTypeId: OperationTypeId { get }

    var duration: Double { get }
    var isComplete: Bool { get }
    mutating func reset()
}

public typealias OperationTypeId = String

public extension OperationPayload {
    var operationTypeId: OperationTypeId { Self.operationTypeId }

    static var InstantDuration: Double { 0 }
    static var InfiniteDuration: Double { -1 }

    /// Equality against an existential. `Equatable` carries a `Self` requirement,
    /// so `AnyOperation` cannot compare two `any OperationPayload` values directly.
    func isEqual(to other: any OperationPayload) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}
