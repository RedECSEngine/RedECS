import RedECS

public struct InteractionComponent<Action: Equatable & Codable>: GameComponent {
    public enum InteractionType: String, Codable, Equatable {
        case proximity
        case selection
    }
    public var entity: EntityId
    public var interactionType: InteractionType
    public var action: Action
    public var radius: Double
    public var triggerTags: Set<String>
    
    public init(
        entity: EntityId,
        interactionType: InteractionType,
        action: Action,
        radius: Double,
        triggerTags: Set<String>
    ) {
        self.entity = entity
        self.interactionType = interactionType
        self.action = action
        self.radius = radius
        self.triggerTags = triggerTags
    }
}

public struct InteractionContext<Action: Equatable & Codable>: GameState {
    public var entities: EntityRepository
    public var transform: [EntityId: TransformComponent]
    public var interaction: [EntityId: InteractionComponent<Action>]
    public init(
        entities: EntityRepository,
        transform: [EntityId: TransformComponent],
        interaction: [EntityId: InteractionComponent<Action>]
    ) {
        self.entities = entities
        self.transform = transform
        self.interaction = interaction
    }
}

/// Triggers interaction components with a proximity interction type when the level's player is in range
public struct InteractionWhenNearbyReducer<Action: Equatable & Codable>: Reducer {
    public init() {}
    public func reduce(
        state: inout InteractionContext<Action>,
        action: Action,
        environment: ()
    ) -> GameEffect<InteractionContext<Action>, Action> { .none }
    
    public func reduce(
        state: inout InteractionContext<Action>,
        delta: Double,
        environment: Void
    ) -> GameEffect<InteractionContext<Action>, Action> {
        var effects = [GameEffect<InteractionContext<Action>, Action>]()
        state.interaction
            .filter { $1.interactionType == .proximity }
            .forEach { interactionId, interaction in
            guard let interactionTransform = state.transform[interactionId] else {
                return
            }
                
            for triggerTag in interaction.triggerTags {
                state.entities.tags[triggerTag]?.forEach({ triggererEntityId in
                    guard let triggererTransform = state.transform[triggererEntityId]
                    else {
                        assertionFailure("missing position component for triggerer")
                        return
                    }
                    if interactionTransform.position.distanceFrom(triggererTransform.position) <= interaction.radius {
                        effects.append(.game(interaction.action))
                    }
                })
            }
        }
        if effects.isEmpty {
            return .none
        } else {
            return .many(effects)
        }
    }
}
