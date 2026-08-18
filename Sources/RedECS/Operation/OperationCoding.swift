public extension CodingUserInfoKey {
    static let operationDecoding = CodingUserInfoKey(rawValue: "redecs.operationDecoding")!
}

public struct OperationDecoderTable: Sendable {
    var decoders: [OperationTypeId: @Sendable (any Decoder) throws -> any OperationPayload] = [:]

    public init() {}

    public var registeredTypeIds: Set<OperationTypeId> { Set(decoders.keys) }

    mutating func insert<O: OperationPayload>(_ type: O.Type, for id: OperationTypeId) {
        decoders[id] = { try O(from: $0) }
    }
}

public enum OperationCodingError: Error, CustomStringConvertible {
    case registrationNotConfigured(OperationTypeId)
    case unknownOperationType(OperationTypeId)

    public var description: String {
        switch self {
        case .registrationNotConfigured(let id):
            return """
            Cannot decode operation '\(id)': no GameRegistration decoder table was supplied. \
            Decode via GameStore(data:environment:reducer:registration:), or set \
            decoder.userInfo[.operationDecoding] = registration.decoderTable.
            """
        case .unknownOperationType(let id):
            return "Cannot decode operation '\(id)': no registration provides it."
        }
    }
}
