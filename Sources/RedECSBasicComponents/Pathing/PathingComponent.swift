import RedECS
import Geometry

public struct PathingComponent: GameComponent {
    public var entity: EntityId
    /// How far from the next target location is "close enough", 0 means precise location
    public var allowableProximityVariance: Double = 1
    public var travelPath: [Point] = []
    
    public init(entity: EntityId) {
        self.entity = entity
    }
}
