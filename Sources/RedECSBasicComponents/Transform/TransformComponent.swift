import RedECS
import Geometry

public struct TransformComponent: GameComponent {
    public let entity: EntityId
    public var position: Point = .zero
    public var rotate: Double = 0
    public var scale: Double = 1
    public var zIndex: Int = 0
    
    public var parentId: EntityId?
    public var isHidden: Bool = false
    
    public init(
        entity: EntityId,
        position: Point = .zero,
        rotate: Double = 0,
        scale: Double = 1,
        zIndex: Int = 0,
        parentId: EntityId? = nil,
        isHidden: Bool = false
    ) {
        self.entity = entity
        self.position = position
        self.rotate = rotate
        self.scale = scale
        self.zIndex = zIndex
        self.parentId = parentId
        self.isHidden = isHidden
    }
}
