public struct TileMapRenderingReducerContext: GameState {
    public var entities: EntityRepository
    public var transform: [EntityId: TransformComponent]
    public var tileMap: [EntityId: TileMapComponent]
    
    public init(
        entities: EntityRepository,
        transform: [EntityId: TransformComponent],
        tileMap: [EntityId: TileMapComponent]
    ) {
        self.entities = entities
        self.transform = transform
        self.tileMap = tileMap
    }
}
