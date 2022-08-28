public protocol RenderableComponent {
    func renderGroups(transform: TransformComponent, resourceManager: ResourceManager) -> [RenderGroup]
}

public protocol RenderableGameState: GameState {
    var transform: [EntityId: TransformComponent] { get }
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
        
        state.entities.entities.forEach { id, entity in
            renderableComponentTypes.forEach { type in
                if let renderComponent = type.renderComponent(entityId: id, state: state),
                   let transform = state.transform[id] {
                    environment.renderer.enqueue(renderComponent.renderGroups(transform: transform, resourceManager: environment.resourceManager))
                }
            }
        }
        return .none
    }
    
    public func reduce(
        state: inout State,
        entityEvent: EntityEvent,
        environment: RenderingEnvironment
    ) {

    }
}


