import Geometry
import GeometryAlgorithms
import RedECS

/// A single line of bitmap-font text at the font's native size. Uses the
/// context's font (set with `.font(_:)`) unless one is given explicitly;
/// with no resolvable font it occupies no space (the engine's silent-skip
/// convention for missing resources). Ignores the proposal: no wrapping
/// or truncation.
public struct Text: BuiltinHUDView {
    public var text: String
    public var fontName: String?

    public init(_ text: String, font fontName: String? = nil) {
        self.text = text
        self.fontName = fontName
    }

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        guard let font = resolvedFont(context) else { return .zero }
        return Size(
            width: font.measure(text).width,
            height: font.common.lineHeight
        )
    }

    public func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        guard let font = resolvedFont(context),
              let layout = try? font.layoutText(text) else {
            return []
        }
        // Glyph quads are laid out y-up with the top of the line box at
        // common.base; flip them into local y-down space so the line's top
        // sits at the origin.
        let flip = Matrix3.identity
            .translatedBy(tx: 0, ty: font.common.base)
            .scaledBy(sx: 1, sy: -1)
        return [
            RenderGroup(
                triangles: layout.triangles,
                transformMatrix: flip,
                fragmentType: .texture(font.pageTextureName),
                zIndex: 0,
                opacity: context.opacity
            )
        ]
    }

    private func resolvedFont(_ context: HUDRenderContext) -> BitmapFont? {
        guard let name = fontName ?? context.font else { return nil }
        return context.fonts[name]
    }
}
