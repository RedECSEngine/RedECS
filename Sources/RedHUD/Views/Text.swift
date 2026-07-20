import Geometry
import GeometryAlgorithms
import RedECS

public struct Text: BuiltinHUDView {
    public var text: String

    public init(_ text: String) {
        self.text = text
    }

    /// The resolved font, its render scale, and the text's size — the shared
    /// layout `size` reports and `resolve` frames at. Nil when no font is set
    /// (both then produce an empty node/`.zero`).
    private func metrics(_ context: HUDRenderContext) -> (font: BitmapFont, scale: Double, size: Size)? {
        guard let font = resolvedFont(context) else { return nil }
        let scale = fontScale(font, context)
        let size = Size(
            width: font.measure(text).width * scale,
            height: font.common.lineHeight * scale
        )
        return (font, scale, size)
    }

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        // Layout-only: measure the string, skip building glyph quads.
        metrics(context)?.size ?? .zero
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        guard let m = metrics(context), let layout = try? m.font.layoutText(text) else {
            return HUDNode(frame: Rect(origin: .zero, size: .zero))
        }
        // Glyph quads are laid out y-up with the top of the line box at
        // common.base; flip them into local y-down space (scaled to the
        // context's font size) so the line's top sits at the origin.
        let flip = Matrix3.flippingYUpToLocal(height: m.font.common.base, scale: m.scale)
        // White glyphs stay on passthrough (unchanged); any other colour tints.
        let shader: ShaderEffect? = context.fillColor == .white
            ? nil
            : .tint(context.fillColor)
        return HUDNode(
            frame: Rect(origin: .zero, size: m.size),
            groups: [
                RenderGroup(
                    triangles: layout.triangles,
                    transformMatrix: flip,
                    fragmentType: .texture(m.font.pageTextureName),
                    zIndex: 0,
                    opacity: context.opacity,
                    projectionSpace: context.projectionSpace,
                    shader: shader // makes foregroundColor actually paint the glyphs
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
