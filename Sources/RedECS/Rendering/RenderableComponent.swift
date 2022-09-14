import Geometry
import GeometryAlgorithms

public protocol RenderableComponent {
    func renderGroups(
        cameraMatrix: Matrix3,
        transform: TransformComponent,
        resourceManager: ResourceManager
    ) -> [RenderGroup]
}

public protocol RenderableGameState: GameState {
    var transform: [EntityId: TransformComponent] { get }
    var camera: [EntityId: CameraComponent] { get }
}

public struct RenderableComponentType<State: GameState> {
    var getRenderComponent: (EntityId, State) -> RenderableComponent?
    
    public init<C: RenderableComponent>(keyPath: KeyPath<State, [EntityId: C]>) {
        getRenderComponent = { id, gameState in
            gameState[keyPath: keyPath][id]
        }
    }
    
    func renderComponent(entityId: EntityId, state: State) -> RenderableComponent? {
       getRenderComponent(entityId, state)
    }
}

public struct RenderingReducer<ContextState: RenderableGameState>: Reducer {
    public typealias State = ContextState
    public typealias Action = Never
    public typealias Environment = RenderingEnvironment
    
    var renderableComponentTypes: [RenderableComponentType<State>]
    
    public init(
        renderableComponentTypes: [RenderableComponentType<State>]
    ) {
        self.renderableComponentTypes = renderableComponentTypes
    }
    
    public func reduce(
        state: inout State,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<State, Never> {
        
        if let camera = state.camera.values.sorted(by: { $1.isPrimaryCamera ? false : true }).first,
           let transform = state.transform[camera.entity] {
            
            let renderer = environment.renderer
            let size = renderer.viewportSize
            let projectionMatrix = camera.matrix(withRect: Rect(center: transform.position, size: size))
            renderer.setProjectionMatrix(projectionMatrix)
            
            state.entities.entities.forEach { id, entity in
                renderableComponentTypes.forEach { type in
                    if let renderComponent = type.renderComponent(entityId: id, state: state),
                       let transform = state.transform[id] {
                        renderer.enqueue(renderComponent.renderGroups(
                            cameraMatrix: projectionMatrix,
                            transform: transform,
                            resourceManager: environment.resourceManager
                        ))
                    }
                }
            }
        }
        return .none
    }
}
