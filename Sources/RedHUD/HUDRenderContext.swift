import RedECS

/// Environment values flowing down the view tree during layout and rendering.
/// Modifier views copy it before passing it to their content; render groups
/// flow back up, so no state escapes a subtree.
public struct HUDRenderContext {
    /// Resource access for views that measure or draw loaded assets
    /// (`Text` fonts, `Sprite` texture maps/animations). Nil in pure
    /// layout contexts (unit tests); views fall back to their
    /// missing-resource behavior.
    public var resourceManager: ResourceManager?
    public var fillColor: Color
    /// The bitmap font face name `Text` uses when none is given explicitly.
    public var font: String?
    public var opacity: Double

    public var fonts: [String: BitmapFont] {
        resourceManager?.fonts ?? [:]
    }

    public init(
        resourceManager: ResourceManager? = nil,
        fillColor: Color = .white,
        font: String? = nil,
        opacity: Double = 1
    ) {
        self.resourceManager = resourceManager
        self.fillColor = fillColor
        self.font = font
        self.opacity = opacity
    }
}
