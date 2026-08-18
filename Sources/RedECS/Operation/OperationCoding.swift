public extension CodingUserInfoKey {
    /// Where `AnyOperation` looks for the tag-to-type table while decoding.
    /// Populated from `GameRegistration.decoderTable`.
    static let operationDecoding = CodingUserInfoKey(rawValue: "redecs.operationDecoding")!
}

/// Maps an encoded operation's type tag back to a concrete payload type.
///
/// Decoding an existential is not possible in Swift — `Decodable.init(from:)` is an
/// initialiser requirement, so a tag string alone gives nothing to call it on. This
/// table is the minimum needed to close that gap, and it is filled in by component
/// registration rather than by hand.
public struct OperationDecoderTable: Sendable {
    var decoders: [OperationTypeId: @Sendable (any Decoder) throws -> any OperationPayload] = [:]

    public init() {}

    public var registeredTypeIds: Set<OperationTypeId> { Set(decoders.keys) }

    mutating func insert<O: OperationPayload>(_ type: O.Type, for id: OperationTypeId) {
        decoders[id] = { try O(from: $0) }
    }
}

public enum OperationCodingError: Error, CustomStringConvertible {
    /// No decoder table was placed in `userInfo[.operationDecoding]`.
    case registrationNotConfigured(OperationTypeId)
    /// The table was present but had no entry for this tag.
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
