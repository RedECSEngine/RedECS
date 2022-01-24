import Foundation

public typealias EntityId = String

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
