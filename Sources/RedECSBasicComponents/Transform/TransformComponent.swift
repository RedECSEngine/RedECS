import RedECS
import Geometry

public struct TransformComponent: GameComponent {
    public let entity: EntityId
    public var translate: Point = .zero
    public var rotate: Double = 0
    public var scale: Double = 1
    
    public init(
        entity: EntityId,
        translate: Point = .zero,
        rotate: Double = 0,
        scale: Double = 1
    ) {
        self.entity = entity
        self.translate = translate
        self.rotate = rotate
        self.scale = scale
    }
}
