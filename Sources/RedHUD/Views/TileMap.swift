import Geometry
import GeometryAlgorithms
import RedECS
import TiledInterpreter

public struct TileMap: BuiltinHUDView {
    public enum Source: Equatable {
        case map(TiledMapJSON)
        case named(String)
    }

    public var source: Source
    public var zoom: Double

    public init(_ map: TiledMapJSON, zoom: Double = 1) {
        self.source = .map(map)
        self.zoom = zoom
    }

    public init(named name: String, zoom: Double = 1) {
        self.source = .named(name)
        self.zoom = zoom
    }

    private func resolvedMap(_ context: HUDRenderContext) -> TiledMapJSON? {
        switch source {
        case .map(let map):
            return map
        case .named(let name):
            return context.resourceManager?.tileMaps[name]
        }
    }

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        guard let map = resolvedMap(context) else { return .zero }
        return Size(width: map.totalWidth * zoom, height: map.totalHeight * zoom)
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        guard let map = resolvedMap(context) else {
            return HUDNode(frame: Rect(origin: .zero, size: .zero))
        }
        let frame = Rect(
            origin: .zero,
            size: Size(width: map.totalWidth * zoom, height: map.totalHeight * zoom)
        )
        guard let resourceManager = context.resourceManager,
              let tileSetName = map.tileSets.first?.source,
              let tileSet = resourceManager.tileSets[tileSetName] else {
            return HUDNode(frame: frame)
        }

        let tileWidth = map.tileWidth,
            tileHeight = map.tileHeight,
            tileSize = Size(width: Double(tileWidth), height: Double(tileHeight))
        let flip = Matrix3.flippingYUpToLocal(height: map.totalHeight, scale: zoom)
        let textureId = tileSet.image.split(separator: ".").dropLast().joined(separator: ".")

        var groups: [RenderGroup] = []
        for layer in map.tileLayers {
            var triangles: [RenderTriangle] = []
            for r in 0..<map.height {
                for c in 0..<map.width {
                    guard let tileIndex = layer.tileDataAt(column: c, row: r, flipY: true),
                          tileIndex != 0 else { continue }

                    let rectForTile = Rect(
                        center: .init(
                            x: Double(c * tileWidth + tileWidth / 2),
                            y: Double(r * tileHeight + tileHeight / 2)
                        ),
                        size: tileSize
                    )

                    let tileSetCol = tileIndex % tileSet.columns - 1
                    let tileSetRow = tileIndex / tileSet.columns
                    let textureRect = Rect(
                        center: .init(
                            x: Double(tileSetCol * tileWidth + tileWidth / 2),
                            y: Double(tileSet.imageHeight) - Double(tileSetRow * tileHeight + tileHeight / 2)
                        ),
                        size: tileSize
                    )

                    triangles.append(RenderTriangle(
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
                    ))
                    triangles.append(RenderTriangle(
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
                    ))
                }
            }
            guard !triangles.isEmpty else { continue }
            groups.append(RenderGroup(
                triangles: triangles,
                transformMatrix: flip,
                fragmentType: .texture(textureId),
                zIndex: 0,
                opacity: context.opacity,
                projectionSpace: context.projectionSpace
            ))
        }
        return HUDNode(frame: frame, groups: groups)
    }
}
