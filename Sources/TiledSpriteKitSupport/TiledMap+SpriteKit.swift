import TiledInterpreter
import SpriteKit

enum TiledError: String, Error {
    case noDataOnLayer
    case notATileLayer
    case couldntCreateTileSet
}

public extension TiledMap {
    func createAllTileMapNodes(tileSet: SKTileSet) throws -> [SKTileMapNode] {
        try (0..<mapInfo.layers.count)
            .compactMap { i in
                guard mapInfo.layers[i].type == .tileLayer else { return nil }
                let mapNode = try createTileMapNode(for: i, tileSet: tileSet)
                mapNode.fill(tiledData: mapInfo.layers[i].data ?? [])
                return mapNode
            }
    }
    
    func createTileMapNode(for index: Int, tileSet: SKTileSet) throws -> SKTileMapNode {
        let layer = mapInfo.layers[index]
        guard layer.type == .tileLayer else {
            throw TiledError.notATileLayer
        }
        guard let data = mapInfo.layers[index].data
        else { throw TiledError.noDataOnLayer }
        
        let tileMapNode = SKTileMapNode(
            tileSet: tileSet,
            columns: mapInfo.width,
            rows: mapInfo.height,
            tileSize: .init(
                width: mapInfo.tileWidth,
                height: mapInfo.tileHeight
            )
        )
        tileMapNode.fill(tiledData: data)
        return tileMapNode
    }
    
    func createScene(imageData: Data) throws -> SKScene {
        guard let tileSet = makeTileset(
            name: tileSetInfo.name,
            imageData: imageData,
            tileWidth: Double(tileSetInfo.tileWidth),
            tileHeight: Double(tileSetInfo.tileHeight)
        ) else {
            throw TiledError.couldntCreateTileSet
        }
        let size = CGSize(
            width: mapInfo.tileWidth * mapInfo.width,
            height: mapInfo.tileHeight * mapInfo.height
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
