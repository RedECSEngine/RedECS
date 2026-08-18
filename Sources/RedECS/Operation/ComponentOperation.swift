/// An operation scoped to a single component.
///
/// This is the ordinary way to add a game operation. The component is handed
/// straight in, so there is no state type to name, no capability protocol to
/// declare, no cast and no state copy. Register it from the component's own
/// `bindOperationSupport`.
public protocol ComponentOperation: OperationPayload {
    associatedtype Component: GameComponent
    associatedtype Action: Equatable & Codable

    mutating func run(
        id: EntityId,
        component: inout Component,
        delta: Double
    ) -> ComponentEffect<Action>
}

/// The effects a component-scoped operation may raise.
///
/// State-free by construction — the registration widens these into
/// `GameEffect<Root, Action>` once it knows the game's state type.
public indirect enum ComponentEffect<Action: Equatable & Codable> {
    case none
    case game(Action)
    case removeEntity(EntityId)
    case removeComponent(EntityId, RegisteredComponentId)
    case addTag(EntityId, String)
    case removeTag(EntityId, String)
    case playSound(SoundId)
    case stopSound(SoundId)
    case stopAllSounds
    case many([Self])

    public func widened<S: GameState>() -> GameEffect<S, Action> {
        switch self {
        case .none:
            return .none
        case .game(let action):
            return .game(action)
        case .removeEntity(let entity):
            return .system(.removeEntity(entity))
        case .removeComponent(let entity, let componentId):
            return .system(.removeComponent(entity, componentId))
        case .addTag(let entity, let tag):
            return .system(.addTag(entity, tag))
        case .removeTag(let entity, let tag):
            return .system(.removeTag(entity, tag))
        case .playSound(let sound):
            return .system(.playSound(sound))
        case .stopSound(let sound):
            return .system(.stopSound(sound))
        case .stopAllSounds:
            return .system(.stopAllSounds)
        case .many(let effects):
            return .many(effects.map { $0.widened() })
        }
    }
}

extension ComponentEffect: Equatable where Action: Equatable {}
