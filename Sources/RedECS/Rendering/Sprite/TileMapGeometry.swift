import Geometry
import GeometryAlgorithms
import TiledInterpreter

public enum TileMapGeometry {
    public struct LayerGeometry {
        public let textureId: TextureId
        public let triangles: [RenderTriangle]
    }

    public static func layerGeometry(
        layer: TiledLayer,
        in map: TiledMapJSON,
        columns: ClosedRange<Int>,
        rows: ClosedRange<Int>,
        animationTime: Double = 0
    ) -> [LayerGeometry] {
        let tileWidth = Double(map.tileWidth)
        let tileHeight = Double(map.tileHeight)
        let offset = Point(x: layer.offsetX, y: -layer.offsetY)

        var trianglesByTileSet: [Int: [RenderTriangle]] = [:]

        for row in rows {
            for column in columns {
                guard let gid = layer.tile(atColumn: column, rowFromBottom: row), !gid.isEmpty,
                      let tileSetIndex = map.tileSetIndex(forGid: gid) else { continue }

                let reference = map.tileSets[tileSetIndex]
                guard let tileSet = reference.tileSet,
                      tileSet.columns > 0,
                      let imageHeight = tileSet.imageHeight else { continue }

                var localId = gid.id - reference.firstGid
                if tileSet.hasAnimatedTiles,
                   let frame = tileSet.tile(withLocalId: localId)?
                    .animationFrame(atMilliseconds: animationTime) {
                    localId = frame.tileId
                }

                guard let textureRect = textureRect(
                    localId: localId,
                    tileSet: tileSet,
                    imageHeight: imageHeight
                ) else { continue }

                let tileRect = Rect(
                    x: offset.x + Double(column) * tileWidth,
                    y: offset.y + Double(row) * tileHeight,
                    width: Double(tileSet.tileWidth),
                    height: Double(tileSet.tileHeight)
                )

                trianglesByTileSet[tileSetIndex, default: []]
                    .append(contentsOf: tileTriangles(tileRect: tileRect, textureRect: textureRect, gid: gid))
            }
        }

        return trianglesByTileSet
            .sorted { $0.key < $1.key }
            .compactMap { tileSetIndex, triangles in
                guard let textureId = map.tileSets[tileSetIndex].tileSet?.textureId else {
                    assertionFailure("tileset has no image to draw from; image collections are unsupported")
                    return nil
                }
                return LayerGeometry(textureId: textureId, triangles: triangles)
            }
    }

    public static func fullExtent(
        of layer: TiledLayer,
        in map: TiledMapJSON
    ) -> (columns: ClosedRange<Int>, rows: ClosedRange<Int>)? {
        let columns = layer.width ?? map.width
        let rows = layer.height ?? map.height
        guard columns > 0, rows > 0 else { return nil }
        return (columns: 0...(columns - 1), rows: 0...(rows - 1))
    }

    static func textureRect(
        localId: Int,
        tileSet: TiledTilesetJSON,
        imageHeight: Int
    ) -> Rect? {
        guard localId >= 0, tileSet.columns > 0 else { return nil }
        let column = localId % tileSet.columns
        let row = localId / tileSet.columns
        let x = tileSet.margin + column * (tileSet.tileWidth + tileSet.spacing)
        let topY = tileSet.margin + row * (tileSet.tileHeight + tileSet.spacing)
        let y = imageHeight - topY - tileSet.tileHeight
        guard y >= 0 else { return nil }
        return Rect(
            x: Double(x),
            y: Double(y),
            width: Double(tileSet.tileWidth),
            height: Double(tileSet.tileHeight)
        )
    }

    static func tileTriangles(
        tileRect: Rect,
        textureRect: Rect,
        gid: TiledGID
    ) -> [RenderTriangle] {
        var corners = [
            Point(x: textureRect.minX, y: textureRect.minY),
            Point(x: textureRect.maxX, y: textureRect.minY),
            Point(x: textureRect.maxX, y: textureRect.maxY),
            Point(x: textureRect.minX, y: textureRect.maxY),
        ]
        if gid.isFlippedDiagonally {
            corners.swapAt(0, 2)
        }
        if gid.isFlippedHorizontally {
            corners.swapAt(0, 1)
            corners.swapAt(2, 3)
        }
        if gid.isFlippedVertically {
            corners.swapAt(0, 3)
            corners.swapAt(1, 2)
        }
        let bottomLeft = corners[0], bottomRight = corners[1]
        let topRight = corners[2], topLeft = corners[3]

        return [
            RenderTriangle(
                triangle: Triangle(
                    a: Point(x: tileRect.minX, y: tileRect.maxY),
                    b: Point(x: tileRect.maxX, y: tileRect.minY),
                    c: Point(x: tileRect.maxX, y: tileRect.maxY)
                ),
                textureTriangle: Triangle(a: topLeft, b: bottomRight, c: topRight)
            ),
            RenderTriangle(
                triangle: Triangle(
                    a: Point(x: tileRect.minX, y: tileRect.minY),
                    b: Point(x: tileRect.maxX, y: tileRect.minY),
                    c: Point(x: tileRect.minX, y: tileRect.maxY)
                ),
                textureTriangle: Triangle(a: bottomLeft, b: bottomRight, c: topLeft)
            ),
        ]
    }
}
