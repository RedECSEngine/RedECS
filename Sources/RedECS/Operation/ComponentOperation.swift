public protocol ComponentOperation: OperationPayload {
    associatedtype Component: GameComponent

    mutating func run(
        id: EntityId,
        component: inout Component,
        delta: Double
    ) -> ComponentEffect
}

public indirect enum ComponentEffect: Equatable {
    case none
    case removeEntity(EntityId)
    case removeComponent(EntityId, RegisteredComponentId)
    case addTag(EntityId, String)
    case removeTag(EntityId, String)
    case playSound(SoundId)
    case stopSound(SoundId)
    case stopAllSounds
    case many([Self])

    public func toGameEffect<S: GameState, Action: Equatable & Codable>() -> GameEffect<S, Action> {
        switch self {
        case .none:
            return .none
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
            return .many(effects.map { $0.toGameEffect() })
        }
    }
}
