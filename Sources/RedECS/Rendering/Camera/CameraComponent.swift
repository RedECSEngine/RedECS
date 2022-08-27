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

public struct CameraReducer: Reducer {
    public init() { }
    public func reduce(
        state: inout CameraReducerContext,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<CameraReducerContext, Never> {
        if let camera = state.camera.values.sorted(by: { $1.isPrimaryCamera ? false : true }).first,
           let transform = state.transform[camera.entity] {
            let renderer = environment.renderer
            let size = renderer.viewportSize
            let projectionMatrix = camera.matrix(withRect: Rect(center: transform.position, size: size))
            renderer.setProjectionMatrix(projectionMatrix)
        }
        return .none
    }
}
