import Geometry
import RedECS

/// Sets the bitmap font face name (and optionally the point size) `Text`
/// views in the subtree use by default.
public struct FontModifier<Content: HUDView>: BuiltinHUDView {
    public var fontName: String
    public var size: Double?
    public var content: Content

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var context = context
        context.font = fontName
        if let size = size {
            context.fontSize = size
        }
        return content._resolve(proposed: proposed, context: context)
    }
}

public extension HUDView {
    func font(_ name: String, size: Double? = nil) -> FontModifier<Self> {
        FontModifier(fontName: name, size: size, content: self)
    }
}
