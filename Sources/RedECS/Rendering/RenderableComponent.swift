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

public struct RootDrawDisposition: Sendable {
    public var isDrawn: Bool
    public var shaderOverride: ShaderEffect?
    public var zIndexOffset: Int

    public init(
        isDrawn: Bool = true,
        shaderOverride: ShaderEffect? = nil,
        zIndexOffset: Int = 0
    ) {
        self.isDrawn = isDrawn
        self.shaderOverride = shaderOverride
        self.zIndexOffset = zIndexOffset
    }

    public static let drawn = RootDrawDisposition()
    public static let hidden = RootDrawDisposition(isDrawn: false)
}

public struct RenderingReducer<ContextState: RenderableGameState>: Reducer {
    public typealias State = ContextState
    public typealias Action = Never
    public typealias Environment = RenderingEnvironment

    var renderableComponentTypes: [RenderableComponentType<State>]
    var rootDrawOrder: ((EntityId, State) -> Double)?
    var rootDrawDisposition: ((EntityId, State) -> RootDrawDisposition)?

    /// - Parameter rootDrawOrder: an optional sort key for the **top-level**
    ///   entities, drawn in ascending order — lowest key first (furthest back),
    ///   highest key last (on top). Subtrees are never reordered: a child draws
    ///   with its parent, in the order it was added.
    ///
    ///   The engine deliberately has no opinion on what the key means. A
    ///   top-down game wanting painter's-algorithm depth passes some function
    ///   of the entity's y — which sign depends entirely on which way its
    ///   world y points, so that decision stays with the game. Omit it and the
    ///   walk keeps plain tree order.
    public init(
        renderableComponentTypes: [RenderableComponentType<State>],
        rootDrawOrder: ((EntityId, State) -> Double)? = nil,
        rootDrawDisposition: ((EntityId, State) -> RootDrawDisposition)? = nil
    ) {
        self.renderableComponentTypes = renderableComponentTypes
        self.rootDrawOrder = rootDrawOrder
        self.rootDrawDisposition = rootDrawDisposition
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
                children: state.entities.hierarchy.roots,
                worldMatrix: .identity,
                state: state,
                projectionMatrix: projectionMatrix,
                environment: environment,
                order: rootDrawOrder,
                disposition: rootDrawDisposition
            )
        }
        return .none
    }

    /// Walks the entity forest depth-first, composing each entity's transform
    /// with its ancestors' so children render in their parent's frame.
    /// A hidden entity hides its entire subtree.
    private func enqueue(
        children: [EntityId],
        worldMatrix: Matrix3,
        state: State,
        projectionMatrix: Matrix3,
        environment: RenderingEnvironment,
        order: ((EntityId, State) -> Double)? = nil,
        disposition: ((EntityId, State) -> RootDrawDisposition)? = nil,
        shaderOverride: ShaderEffect? = nil,
        zIndexOffset: Int = 0
    ) {
        for entityId in Self.ordered(children, by: order, in: state) {
            var shaderOverride = shaderOverride
            var zIndexOffset = zIndexOffset
            if let disposition {
                let rootDisposition = disposition(entityId, state)
                if !rootDisposition.isDrawn {
                    continue
                }
                shaderOverride = rootDisposition.shaderOverride
                zIndexOffset = rootDisposition.zIndexOffset
            }

            let transform = state.transform[entityId]
            if transform?.isHidden == true {
                continue
            }

            if let transform = transform {
                for type in renderableComponentTypes {
                    guard let renderComponent = type.renderComponent(entityId: entityId, state: state) else {
                        continue
                    }
                    let groups = renderComponent.renderGroups(
                        cameraMatrix: .multiply(projectionMatrix, worldMatrix),
                        transform: transform,
                        resourceManager: environment.resourceManager
                    )
                    environment.renderer.enqueue(groups.map { group in
                        var reparented = group.withTransformMatrix(.multiply(worldMatrix, group.transformMatrix))
                        if zIndexOffset != 0 {
                            reparented = reparented.withZIndexOffset(zIndexOffset)
                        }
                        if let shaderOverride {
                            reparented = reparented.withShader(shaderOverride)
                        }
                        return reparented
                    })
                }
            }

            // Children inherit position/rotation/scale, but not the
            // anchor-point offset (that only affects the parent's own drawing).
            let childWorldMatrix = transform.map { .multiply(worldMatrix, $0.matrix()) } ?? worldMatrix
            enqueue(
                children: state.entities.hierarchy.children(of: entityId),
                worldMatrix: childWorldMatrix,
                state: state,
                projectionMatrix: projectionMatrix,
                environment: environment,
                shaderOverride: shaderOverride,
                zIndexOffset: zIndexOffset
            )
        }
    }

    /// Stable: entities with an equal key keep the order they were added in,
    /// so a tie can't shimmer between frames.
    private static func ordered(
        _ ids: [EntityId],
        by order: ((EntityId, State) -> Double)?,
        in state: State
    ) -> [EntityId] {
        guard let order else { return ids }
        return ids
            .enumerated()
            .sorted { a, b in
                let ka = order(a.element, state), kb = order(b.element, state)
                return ka == kb ? a.offset < b.offset : ka < kb
            }
            .map(\.element)
    }
}
