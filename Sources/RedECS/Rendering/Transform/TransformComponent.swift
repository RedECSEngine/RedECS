import Geometry
import GeometryAlgorithms

public struct TransformComponent: GameComponent {
    public let entity: EntityId
    public var position: Point = .zero
    public private(set) var anchorPoint: Point = .init(x: 0.5, y: 0.5) // From 0 to 1
    public var rotate: Double = 0
    public var scale: Point = Point(x: 1, y: 1)
    public var zIndex: Int = 0
    
    public var parentId: EntityId? // TODO: implement rendering implications
    public var isHidden: Bool = false // TODO: implement rendering implications
    
    public init(entity: EntityId) {
        self = .init(entity: entity, position: .zero)
    }
    
    public init(
        entity: EntityId,
        position: Point = .zero,
        anchorPoint: Point = .init(x: 0.5, y: 0.5),
        rotate: Double = 0,
        scale: Point = Point(x: 1, y: 1),
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
        
        self.setAnchorPoint(anchorPoint)
    }
    
    public func matrix(containerSize: Size = .zero) -> Matrix3 {
      Matrix3
            .identity
            .translatedBy(tx: position.x, ty: position.y)
            .rotatedBy(angleInRadians: -rotate.degreesToRadians())
            .scaledBy(sx: scale.x, sy: scale.y)
            .translatedBy(
                tx: -anchorPoint.x * containerSize.width,
                ty: -anchorPoint.y * containerSize.height
            )
    }
    
    /// Clamps values between 0 and 1.  A value of 0.5 for both x and y means center
    public mutating func setAnchorPoint(_ anchorPoint: Point) {
        self.anchorPoint = .init(
            x: max(0, min(1, anchorPoint.x)),
            y: max(0, min(1, anchorPoint.y))
        )
    }
}
