public protocol OperationPayload: Codable, Equatable {
    static var operationTypeId: OperationTypeId { get }

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

    func isEqual(to other: any OperationPayload) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}
