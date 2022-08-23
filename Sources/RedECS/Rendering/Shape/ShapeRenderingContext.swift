public struct ShapeRenderingContext: GameState {
    public var entities: EntityRepository = .init()
    public var transform: [EntityId: TransformComponent]
    public var shape: [EntityId: ShapeComponent]
    
    public init(
        entities: EntityRepository = .init(),
        transform: [EntityId: TransformComponent],
        shape: [EntityId: ShapeComponent]
    ) {
        self.entities = entities
        self.transform = transform
        self.shape = shape
    }
}
