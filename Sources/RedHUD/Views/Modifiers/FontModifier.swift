import Geometry
import RedECS

/// Sets the bitmap font face name (and optionally the point size) `Text`
/// views in the subtree use by default.
public struct FontModifier<Content: HUDView>: BuiltinHUDView {
    public var fontName: String
    public var size: Double?
    public var content: Content

    /// The context with this modifier's font (and optional size) applied,
    /// shared by `size` and `resolve`.
    private func applied(to context: HUDRenderContext) -> HUDRenderContext {
        var context = context
        context.font = fontName
        if let size = size {
            context.fontSize = size
        }
        return context
    }

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        content._size(proposed: proposed, context: applied(to: context))
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        content._resolve(proposed: proposed, context: applied(to: context))
    }
}

public extension HUDView {
    func font(_ name: String, size: Double? = nil) -> FontModifier<Self> {
        FontModifier(fontName: name, size: size, content: self)
    }
}
