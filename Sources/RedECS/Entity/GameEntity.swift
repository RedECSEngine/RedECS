import Foundation

public typealias EntityId = String

public func newEntityId(prefix: String? = nil) -> EntityId {
    let prefix = prefix.map({ "\($0)-" }) ?? ""
    return prefix + "\(Int.random(in: 0...Int.max))"
}

public struct GameEntity: Hashable, Identifiable, Codable {
    public var id: EntityId
    public var tags: Set<String>
    
    public init(
        id: EntityId,
        tags: Set<String>
    ) {
        self.id = id
        self.tags = tags
    }
}
