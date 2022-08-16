import RedECS

public struct BasicOperationComponentContext: GameState {
    public var entities: EntityRepository = .init()
    public var transform: [EntityId: TransformComponent] = [:]
    
    public init(
        entities: EntityRepository = .init(),
        transform: [EntityId: TransformComponent] = [:]
    ) {
        self.entities = entities
        self.transform = transform
    }
}
