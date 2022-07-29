import Foundation
import SpriteKit
import XMLCoder
import TiledInterpreter

public extension TiledMap {
    init(
        mapJSONData: Data,
        tileSetXMLData: Data
    ) throws {
        try self.init(
            mapInfo: try JSONDecoder().decode(TiledMapInfoJSON<TOT>.self, from: mapJSONData),
            tileSetInfo: try XMLDecoder().decode(TiledTilesetXML<TTC>.self, from: tileSetXMLData).toJSONFormat()
        )
    }
}
