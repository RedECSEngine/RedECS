import SpriteKit
import Geometry
import RedECS
import RedECSBasicComponents

public struct SpriteAnimatingComponent: GameComponent {
    public var entity: EntityId
    public var atlasName: String
    public init(
        entity: EntityId,
        atlasName: String
    ) {
        self.entity = entity
        self.atlasName = atlasName
    }
}
