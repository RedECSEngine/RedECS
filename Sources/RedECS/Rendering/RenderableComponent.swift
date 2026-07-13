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

            enqueue(
                childrenOf: state.entities.tree,
                worldMatrix: .identity,
                state: state,
                projectionMatrix: projectionMatrix,
                environment: environment
            )
        }
        return .none
    }

    /// Walks the entity tree depth-first, composing each entity's transform
    /// with its ancestors' so children render in their parent's frame.
    /// A hidden entity hides its entire subtree.
    private func enqueue(
        childrenOf tree: EntityTree,
        worldMatrix: Matrix3,
        state: State,
        projectionMatrix: Matrix3,
        environment: RenderingEnvironment
    ) {
        for node in tree.children ?? [] {
            let transform = state.transform[node.id]
            if transform?.isHidden == true {
                continue
            }

            if let transform = transform {
                for type in renderableComponentTypes {
                    guard let renderComponent = type.renderComponent(entityId: node.id, state: state) else {
                        continue
                    }
                    let groups = renderComponent.renderGroups(
                        cameraMatrix: .multiply(projectionMatrix, worldMatrix),
                        transform: transform,
                        resourceManager: environment.resourceManager
                    )
                    environment.renderer.enqueue(groups.map { group in
                        group.withTransformMatrix(.multiply(worldMatrix, group.transformMatrix))
                    })
                }
            }

            // Children inherit position/rotation/scale, but not the
            // anchor-point offset (that only affects the parent's own drawing).
            let childWorldMatrix = transform.map { .multiply(worldMatrix, $0.matrix()) } ?? worldMatrix
            enqueue(
                childrenOf: node,
                worldMatrix: childWorldMatrix,
                state: state,
                projectionMatrix: projectionMatrix,
                environment: environment
            )
        }
    }
}
