import Geometry
import GeometryAlgorithms

public struct CameraComponent: GameComponent {
    public let entity: EntityId
    public var zoom: Double = 1
    public var offset: Point = .zero
    public var isPrimaryCamera: Bool = true
    
    public init(entity: EntityId) {
        self = .init(entity: entity, zoom: 1)
    }
    
    public init(
        entity: EntityId,
        zoom: Double = 1,
        offset: Point = .zero,
        isPrimaryCamera: Bool = true
    ) {
        self.entity = entity
        self.zoom = zoom
        self.offset = offset
        self.isPrimaryCamera = isPrimaryCamera
    }
    
    public func matrix(withRect rect: Rect) -> Matrix3 {
        Matrix3.projection(rect: rect, zoom: zoom)
    }
}
