import Geometry
import GeometryAlgorithms
import TiledInterpreter

extension SpriteComponent {
    func tileMapRenderGroups(
        tileMap: TiledMapJSON,
        cameraMatrix: Matrix3,
        transform: TransformComponent
    ) -> [RenderGroup] {
        guard tileMap.width > 0, tileMap.height > 0, tileMap.tileWidth > 0, tileMap.tileHeight > 0 else {
            return []
        }
        if let orientation = tileMap.orientation, orientation != "orthogonal" {
            assertionFailure("only orthogonal tile maps render; got \(orientation)")
            return []
        }
        if !tileMap.unresolvedTileSetSources.isEmpty {
            assertionFailure("tile map tilesets are unresolved: \(tileMap.unresolvedTileSetSources)")
        }

        let mapSize = Size(width: tileMap.totalWidth, height: tileMap.totalHeight)
        let matrix = contentMatrix(transform: transform, containerSize: mapSize)
        guard let visible = visibleContentRect(
            projection: .multiply(cameraMatrix, matrix),
            in: tileMap
        ) else { return [] }

        var renderGroups: [RenderGroup] = []
        for layer in tileMap.tileLayers where layer.visible && layer.opacity > 0 {
            guard let window = visibleWindow(of: layer, in: tileMap, visible: visible) else { continue }
            renderGroups += TileMapGeometry.layerGeometry(
                layer: layer,
                in: tileMap,
                columns: window.columns,
                rows: window.rows,
                animationTime: tileAnimationTime
            ).map { geometry in
                RenderGroup(
                    triangles: geometry.triangles,
                    transformMatrix: matrix,
                    fragmentType: .texture(geometry.textureId),
                    zIndex: transform.zIndex,
                    opacity: opacity * layer.opacity,
                    shader: shader
                )
            }
        }
        return renderGroups
    }

    private func visibleWindow(
        of layer: TiledLayer,
        in tileMap: TiledMapJSON,
        visible: Rect
    ) -> (columns: ClosedRange<Int>, rows: ClosedRange<Int>)? {
        let tileWidth = Double(tileMap.tileWidth)
        let tileHeight = Double(tileMap.tileHeight)
        let columns = layer.width ?? tileMap.width
        let rows = layer.height ?? tileMap.height
        guard columns > 0, rows > 0 else { return nil }

        let offsetX = layer.offsetX
        let offsetY = -layer.offsetY

        let firstColumn = max(0, Int(((visible.minX - offsetX) / tileWidth).rounded(.down)))
        let lastColumn = min(columns - 1, Int(((visible.maxX - offsetX) / tileWidth).rounded(.down)))
        let firstRow = max(0, Int(((visible.minY - offsetY) / tileHeight).rounded(.down)))
        let lastRow = min(rows - 1, Int(((visible.maxY - offsetY) / tileHeight).rounded(.down)))
        guard firstColumn <= lastColumn, firstRow <= lastRow else { return nil }

        return (columns: firstColumn...lastColumn, rows: firstRow...lastRow)
    }

    private func visibleContentRect(projection: Matrix3, in tileMap: TiledMapJSON) -> Rect? {
        let inverse = projection.calculateInverse()
        guard inverse.values.allSatisfy({ $0.isFinite }) else { return nil }

        let corners = [
            Point(x: -1, y: -1),
            Point(x: 1, y: -1),
            Point(x: 1, y: 1),
            Point(x: -1, y: 1),
        ].map { $0.multiplyingMatrix(inverse) }

        guard corners.allSatisfy({ $0.x.isFinite && $0.y.isFinite }) else { return nil }

        let xs = corners.map(\.x), ys = corners.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return nil }

        let largest = tileMap.maximumTileSize
        let overhangX = Double(max(0, largest.width - tileMap.tileWidth))
        let overhangY = Double(max(0, largest.height - tileMap.tileHeight))
        return Rect(
            x: minX - overhangX,
            y: minY - overhangY,
            width: (maxX - minX) + overhangX,
            height: (maxY - minY) + overhangY
        )
    }
}
