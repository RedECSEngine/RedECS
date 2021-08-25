import Foundation
import RedECS
import Geometry

public struct SeparationComponent: GameComponent {
    public var entity: EntityId
    public var radius: Double
    public init(
        entity: EntityId,
        radius: Double
    ) {
        self.entity = entity
        self.radius = radius
    }
}
