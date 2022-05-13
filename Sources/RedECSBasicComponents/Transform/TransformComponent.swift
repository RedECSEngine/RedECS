import RedECS
import Geometry

public struct TransformComponent: GameComponent {
    public let entity: EntityId
    public var position: Point = .zero
    public var rotate: Double = 0
    public var scale: Double = 1
    
    public var parentId: EntityId?
    
    public init(
        entity: EntityId,
        position: Point = .zero,
        rotate: Double = 0,
        scale: Double = 1,
        parentId: EntityId? = nil
    ) {
        self.entity = entity
        self.position = position
        self.rotate = rotate
        self.scale = scale
        self.parentId = parentId
    }
}
