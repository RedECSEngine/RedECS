import RedECS
import Geometry

public struct MovementComponent: GameComponent {
    public let entity: EntityId
    public var velocity: Point
    public var travelSpeed: Double
    public var recentVelocityHistory: [Point] = []
    public init(
        entity: EntityId,
        velocity: Point,
        travelSpeed: Double
    ) {
        self.entity = entity
        self.velocity = velocity
        self.travelSpeed = travelSpeed
    }
}
