import Geometry
import GeometryAlgorithms

/// A pure spatial frame: position, rotation and scale. Content-related
/// offsets (like a sprite's anchor point) belong to the renderable that
/// draws in this frame, not to the frame itself.
public struct TransformComponent: GameComponent {
    public let entity: EntityId
    public var position: Point = .zero
    public var rotate: Double = 0
    public var scale: Point = Point(x: 1, y: 1)
    public var zIndex: Int = 0
    public var isHidden: Bool = false

    public init(entity: EntityId) {
        self = .init(entity: entity, position: .zero)
    }

    public init(
        entity: EntityId,
        position: Point = .zero,
        rotate: Double = 0,
        scale: Point = Point(x: 1, y: 1),
        zIndex: Int = 0,
        isHidden: Bool = false
    ) {
        self.entity = entity
        self.position = position
        self.rotate = rotate
        self.scale = scale
        self.zIndex = zIndex
        self.isHidden = isHidden
    }

    public func matrix() -> Matrix3 {
      Matrix3
            .identity
            .translatedBy(tx: position.x, ty: position.y)
            .rotatedBy(angleInRadians: -rotate.degreesToRadians())
            .scaledBy(sx: scale.x, sy: scale.y)
    }
}
