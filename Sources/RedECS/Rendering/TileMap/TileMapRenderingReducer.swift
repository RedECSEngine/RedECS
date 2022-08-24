import Geometry
import GeometryAlgorithms

public struct TileMapRenderingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout TileMapRenderingReducerContext,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<TileMapRenderingReducerContext, Never> {
        state.tileMap.forEach { (id, tileMap) in
            guard let transform = state.transform[id] else { return }
            
//            let cameraRect = environment.renderer.cameraFrame
            
            let tileWidth = tileMap.tileMap.tileWidth,
                tileHeight = tileMap.tileMap.tileHeight,
                layerCols = tileMap.tileMap.width,
                layerRows = tileMap.tileMap.height,
                tileSize = Size(width: Double(tileWidth), height: Double(tileHeight))
            
            tileMap.tileMap.tileLayers.enumerated().forEach { (i, layer) in
                guard let tileSetName = tileMap.tileMap.tileSets.first?.source,
                      let tileSet = environment.resourceManager.tileSets[tileSetName] else {
                    return
                }
                
                let matrix = transform.matrix(containerSize: Size(
                    width: tileMap.tileMap.totalWidth,
                    height: tileMap.tileMap.totalHeight
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
                        
//                        guard cameraRect.contains(rectForTile.offset(by: transform.position)) else { continue }
                        
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
                
                let textureId = tileSet.image.split(separator: ".").dropLast().joined(separator: ".")
                environment.renderer.enqueue([
                    RenderGroup(
                        triangles: renderTriangles,
                        transformMatrix: matrix,
                        fragmentType: .texture(textureId),
                        zIndex: transform.zIndex
                    )
                ])
                
            }
        }
        return .none
    }
}
