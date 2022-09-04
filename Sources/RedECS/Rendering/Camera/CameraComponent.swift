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

public struct CameraReducerContext: GameState {
    public var entities: EntityRepository = .init()
    
    public var transform: [EntityId: TransformComponent] = [:]
    public var camera: [EntityId: CameraComponent] = [:]
    
    public init(
        entities: EntityRepository = .init(),
        transform: [EntityId: TransformComponent] = [:],
        camera: [EntityId: CameraComponent] = [:]
    ) {
        self.entities = entities
        self.transform = transform
        self.camera = camera
    }
}
