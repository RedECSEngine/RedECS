
public protocol BasicOperationCapableState: GameState {
    var transform: [EntityId: TransformComponent] { get set }
    var sprite: [EntityId: SpriteComponent] { get set }
}
