import RedECS
import Geometry

public struct MomentumComponent: GameComponent {
    public let entity: EntityId
    public var velocity: Point
    public init(
        entity: EntityId,
        velocity: Point
    ) {
        self.entity = entity
        self.velocity = velocity
    }
}
