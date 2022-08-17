import TiledInterpreter
import SpriteKit

enum TiledError: String, Error {
    case noDataOnLayer
    case notATileLayer
    case couldntCreateTileSet
}

public extension TiledMapJSON {
    func createAllTileMapNodes(tileSet: SKTileSet) throws -> [SKTileMapNode] {
        try (0..<layers.count)
            .compactMap { i in
                guard layers[i].type == .tileLayer else { return nil }
                let mapNode = try createTileMapNode(for: i, tileSet: tileSet)
                mapNode.fill(tiledData: layers[i].data ?? [])
                return mapNode
            }
    }
    
    func createTileMapNode(for index: Int, tileSet: SKTileSet) throws -> SKTileMapNode {
        let layer = layers[index]
        guard layer.type == .tileLayer else {
            throw TiledError.notATileLayer
        }
        guard let data = layers[index].data
        else { throw TiledError.noDataOnLayer }
        
        let tileMapNode = SKTileMapNode(
            tileSet: tileSet,
            columns: width,
            rows: height,
            tileSize: .init(
                width: tileWidth,
                height: tileHeight
            )
        )
        tileMapNode.fill(tiledData: data)
        return tileMapNode
    }
    
    func createScene(tileSetName: String, imageData: Data) throws -> SKScene {
        guard let tileSet = makeTileset(
            name: tileSetName,
            imageData: imageData,
            tileWidth: Double(tileWidth),
            tileHeight: Double(tileHeight)
        ) else {
            throw TiledError.couldntCreateTileSet
        }
        let size = CGSize(
            width: tileWidth * width,
            height: tileHeight * height
        )
        let scene = SKScene(size: size)
        try createAllTileMapNodes(tileSet: tileSet)
            .forEach { mapNode in
                mapNode.position = .init(x: size.width/2, y: size.height/2)
                scene.addChild(mapNode)
            }
        return scene
    }
}
