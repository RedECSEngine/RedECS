import Geometry
import GeometryAlgorithms
import RedECS

public struct Text: BuiltinHUDView {
    public var text: String

    public init(_ text: String) {
        self.text = text
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        guard let font = resolvedFont(context),
              let layout = try? font.layoutText(text) else {
            return HUDNode(frame: Rect(origin: .zero, size: .zero))
        }
        let size = Size(
            width: font.measure(text).width,
            height: font.common.lineHeight
        )
        // Glyph quads are laid out y-up with the top of the line box at
        // common.base; flip them into local y-down space so the line's top
        // sits at the origin.
        let flip = Matrix3.identity
            .translatedBy(tx: 0, ty: font.common.base)
            .scaledBy(sx: 1, sy: -1)
        return HUDNode(
            frame: Rect(origin: .zero, size: size),
            groups: [
                RenderGroup(
                    triangles: layout.triangles,
                    transformMatrix: flip,
                    fragmentType: .texture(font.pageTextureName),
                    zIndex: 0,
                    opacity: context.opacity
                )
            ]
        )
    }

    /// The context's font when it names a loaded one; otherwise the loaded
    /// copy of the default face, falling back to the embedded default so
    /// text always measures and renders without game-side font setup.
    private func resolvedFont(_ context: HUDRenderContext) -> BitmapFont? {
        if let name = context.font, let font = context.fonts[name] {
            return font
        }
        return context.fonts[DefaultHUDFont.font.info.face] ?? DefaultHUDFont.font
    }
}
