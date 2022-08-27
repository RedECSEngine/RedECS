import RedECS
import Geometry

public struct FollowEntityComponent: GameComponent {
    public var entity: EntityId
    public var leaderId: EntityId
    public var maxDistance: Double
    
    public init(entity: EntityId) {
        self = .init(entity: entity, leaderId: "", maxDistance: .greatestFiniteMagnitude)
    }

    public init(entity: EntityId, leaderId: EntityId, maxDistance: Double) {
        self.entity = entity
        self.leaderId = leaderId
        self.maxDistance = maxDistance
    }
}
