import RedECS
import TiledInterpreter

public struct TileMapComponent: GameComponent {
    public var entity: EntityId
    public var tileMap: TiledMapJSON
    
    public init(
        entity: EntityId,
        tileMap: TiledMapJSON
    ) {
        self.entity = entity
        self.tileMap = tileMap
    }
}
