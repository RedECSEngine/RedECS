import TiledInterpreter
import Geometry
import GeometryAlgorithms

public struct TileMapComponent: GameComponent {
    public var entity: EntityId
    public var tileMap: TiledMapJSON?
    
    public init(entity: EntityId) {
        self.entity = entity
        self.tileMap = nil
    }
    
    public init(
        entity: EntityId,
        tileMap: TiledMapJSON
    ) {
        self.entity = entity
        self.tileMap = tileMap
    }
}

extension TileMapComponent: RenderableComponent {
    public func renderGroups(
        cameraMatrix: Matrix3,
        transform: TransformComponent,
        resourceManager: ResourceManager
    ) -> [RenderGroup] {
        guard let tileMap = tileMap else { return [] }
        let tileWidth = tileMap.tileWidth,
            tileHeight = tileMap.tileHeight,
            layerCols = tileMap.width,
            layerRows = tileMap.height,
            tileSize = Size(width: Double(tileWidth), height: Double(tileHeight))
        
        var renderGroups = [RenderGroup]()
        tileMap.tileLayers.enumerated().forEach { (i, layer) in
            guard let tileSetName = tileMap.tileSets.first?.source,
                  let tileSet = resourceManager.tileSets[tileSetName] else {
                return
            }
            
            let matrix = transform.matrix(containerSize: Size(
                width: tileMap.totalWidth,
                height: tileMap.totalHeight
            ))
            
            var renderTriangles: [RenderTriangle] = []
            
            for r in 0..<layerRows {
                for c in 0..<layerCols {
                    let rectForTile = Rect(
                        center: .init(
                            x: Double(c * tileWidth + tileWidth / 2),
                            y: Double(r * tileHeight + tileHeight / 2)
                        ),
                        size: tileSize
                    )
                    
                    let projectedPosition = rectForTile.center.multiplyingMatrix(cameraMatrix)
                    if abs(projectedPosition.x) > 1.125 || abs(projectedPosition.y) > 1.125 {
                        continue
                    }
                    
                    guard let tileIndex = layer.tileDataAt(column: c, row: r, flipY: true) else { continue }
                    
                    guard tileIndex != 0 else { continue } // empty
                    
                    let tileSetCol = (tileIndex) % tileSet.columns - 1
                    let tileSetRow = ((tileIndex) / tileSet.columns)
                    
                    let textureRect = Rect(
                        center: .init(
                            x: Double(tileSetCol * tileWidth + tileWidth / 2),
                            y: Double(tileSet.imageHeight) - Double(tileSetRow * tileHeight + tileHeight / 2)
                        ),
                        size: tileSize
                    )
                    
                    let topRenderTri = RenderTriangle(
                        triangle: Triangle(
                            a: Point(x: rectForTile.minX, y: rectForTile.maxY),
                            b: Point(x: rectForTile.maxX, y: rectForTile.minY),
                            c: Point(x: rectForTile.maxX, y: rectForTile.maxY)
                        ),
                        textureTriangle: Triangle(
                            a: Point(x: textureRect.minX, y: textureRect.maxY),
                            b: Point(x: textureRect.maxX, y: textureRect.minY),
                            c: Point(x: textureRect.maxX, y: textureRect.maxY)
                        )
                    )
                    let bottomRenderTri = RenderTriangle(
                        triangle: Triangle(
                            a: Point(x: rectForTile.minX, y: rectForTile.minY),
                            b: Point(x: rectForTile.maxX, y: rectForTile.minY),
                            c: Point(x: rectForTile.minX, y: rectForTile.maxY)
                        ),
                        textureTriangle: Triangle(
                            a: Point(x: textureRect.minX, y: textureRect.minY),
                            b: Point(x: textureRect.maxX, y: textureRect.minY),
                            c: Point(x: textureRect.minX, y: textureRect.maxY)
                        )
                    )
                    
                    renderTriangles.append(contentsOf: [topRenderTri, bottomRenderTri])
                }
            }
            
            guard !renderTriangles.isEmpty else {
                return
            }
            
            let textureId = tileSet.image.split(separator: ".").dropLast().joined(separator: ".")
            renderGroups.append(RenderGroup(
                triangles: renderTriangles,
                transformMatrix: matrix,
                fragmentType: .texture(textureId),
                zIndex: transform.zIndex
            ))
        }
        return renderGroups
    }
}
