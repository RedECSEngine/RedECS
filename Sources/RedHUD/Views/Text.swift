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
        let scale = fontScale(font, context)
        let size = Size(
            width: font.measure(text).width * scale,
            height: font.common.lineHeight * scale
        )
        // Glyph quads are laid out y-up with the top of the line box at
        // common.base; flip them into local y-down space (scaled to the
        // context's font size) so the line's top sits at the origin.
        let flip = Matrix3.flippingYUpToLocal(height: font.common.base, scale: scale)
        return HUDNode(
            frame: Rect(origin: .zero, size: size),
            groups: [
                RenderGroup(
                    triangles: layout.triangles,
                    transformMatrix: flip,
                    fragmentType: .texture(font.pageTextureName),
                    zIndex: 0,
                    opacity: context.opacity,
                    projectionSpace: context.projectionSpace
                )
            ]
        )
    }

    /// Layout-and-render scale from the font's native size to the context's
    /// `fontSize`; 1 when no size is set or the font declares none.
    private func fontScale(_ font: BitmapFont, _ context: HUDRenderContext) -> Double {
        guard let fontSize = context.fontSize, font.info.size > 0 else { return 1 }
        return fontSize / font.info.size
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
