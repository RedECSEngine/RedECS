import RedECS
import RedECSBasicComponents
import Geometry
import TiledInterpreter

public struct TileMapComponent<TOT: TiledObjectType, TTC: TiledTileClass>: GameComponent {
    public var entity: EntityId
    public var tileMap: TiledMap<TOT, TTC>
    public var textureId: TextureId
    
    public init(
        entity: EntityId,
        tileMap: TiledMap<TOT, TTC>,
        textureId: TextureId
    ) {
        self.entity = entity
        self.tileMap = tileMap
        self.textureId = textureId
    }
}

public struct TileMapRenderingReducerContext<TOT: TiledObjectType, TTC: TiledTileClass>: GameState {
    public var entities: EntityRepository
    public var transform: [EntityId: TransformComponent]
    public var tileMap: [EntityId: TileMapComponent<TOT, TTC>]
    
    public init(
        entities: EntityRepository,
        transform: [EntityId: TransformComponent],
        tileMap: [EntityId: TileMapComponent<TOT, TTC>]
    ) {
        self.entities = entities
        self.transform = transform
        self.tileMap = tileMap
    }
}

public struct TileMapRenderingReducer<TOT: TiledObjectType, TTC: TiledTileClass>: Reducer {
    public init() {}
    public func reduce(
        state: inout TileMapRenderingReducerContext<TOT, TTC>,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<TileMapRenderingReducerContext<TOT, TTC>, Never> {
        state.tileMap.forEach { (id, tileMap) in
            guard let transform = state.transform[id] else { return }
            
            let cameraRect = environment.renderer.cameraFrame
            
            let tileWidth = tileMap.tileMap.mapInfo.tileWidth,
                tileHeight = tileMap.tileMap.mapInfo.tileHeight,
                layerCols = tileMap.tileMap.mapInfo.width,
                layerRows = tileMap.tileMap.mapInfo.height,
                tileSize = Size(width: Double(tileWidth), height: Double(tileHeight))
            
            tileMap.tileMap.tileLayers.forEach { layer in
                guard let data = layer.data else { return }
                for r in 0..<layerRows {
                    for c in 0..<layerCols {
                        let rectForTile = Rect(
                            center: .init(
                                x: Double(c * tileWidth + tileWidth / 2),
                                y: Double(r * tileHeight + tileHeight / 2)
                            ),
                            size: tileSize
                        )
                        
                        let renderRect = rectForTile.offset(by: transform.position)
                        guard cameraRect.contains(renderRect) else { return }
                        
                        let index = c + (r * layerCols)
                        let tileIndex = data[index]
                        let tileSetCol = tileIndex % tileMap.tileMap.tileSetInfo.columns
                        let tileSetRow = tileIndex / tileMap.tileMap.tileSetInfo.columns
                        
                        let textureRect = Rect(
                            center: .init(
                                x: Double(tileSetCol * tileWidth + tileWidth / 2),
                                y: Double(tileSetRow * tileHeight + tileHeight / 2)
                            ),
                            size: tileSize
                        )
                        
                        let topRenderTri = RenderTriangle(
                            triangle: Triangle(
                                a: Point(x: renderRect.minX, y: renderRect.maxY),
                                b: Point(x: renderRect.maxX, y: renderRect.minY),
                                c: Point(x: renderRect.maxX, y: renderRect.maxY)
                            ),
                            fragmentType: .texture(
                                tileMap.textureId,
                                Triangle(
                                    a: Point(x: textureRect.minX, y: textureRect.maxY),
                                    b: Point(x: textureRect.maxX, y: textureRect.minY),
                                    c: Point(x: textureRect.maxX, y: textureRect.maxY)
                                )
                            ),
                            zIndex: transform.zIndex
                        )
                        let bottomRenderTri = RenderTriangle(
                            triangle: Triangle(
                                a: Point(x: renderRect.minX, y: renderRect.minY),
                                b: Point(x: renderRect.maxX, y: renderRect.minY),
                                c: Point(x: renderRect.minX, y: renderRect.maxY)
                            ),
                            fragmentType: .texture(
                                tileMap.textureId,
                                Triangle(
                                    a: Point(x: textureRect.minX, y: textureRect.minY),
                                    b: Point(x: textureRect.maxX, y: textureRect.minY),
                                    c: Point(x: textureRect.minX, y: textureRect.maxY)
                                )
                            ),
                            zIndex: transform.zIndex
                        )
                        
                        environment.renderer.enqueueTriangles([
                            bottomRenderTri,
                            topRenderTri,
                        ])
                    }
                }
            }
            
        }
        return .none
    }
}
