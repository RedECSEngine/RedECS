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
        let flip = Matrix3.flippingYUpToLocal(height: map.totalHeight, scale: zoom)

        var groups: [RenderGroup] = []
        for layer in map.tileLayers where layer.visible && layer.opacity > 0 {
            guard let extent = TileMapGeometry.fullExtent(of: layer, in: map) else { continue }
            groups += TileMapGeometry.layerGeometry(
                layer: layer,
                in: map,
                columns: extent.columns,
                rows: extent.rows
            ).map { geometry in
                RenderGroup(
                    triangles: geometry.triangles,
                    transformMatrix: flip,
                    fragmentType: .texture(geometry.textureId),
                    zIndex: 0,
                    opacity: context.opacity * layer.opacity,
                    projectionSpace: context.projectionSpace
                )
            }
        }
        return HUDNode(frame: frame, groups: groups)
    }
}
