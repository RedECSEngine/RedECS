import RedECS
import Geometry

public struct PositionComponent: GameComponent {
    public let entity: EntityId
    public var point: Point
    
    public init(entity: EntityId, point: Point) {
        self.entity = entity
        self.point = point
    }
}
