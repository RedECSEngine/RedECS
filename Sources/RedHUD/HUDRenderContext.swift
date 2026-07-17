import RedECS

/// Environment values flowing down the view tree during layout and rendering.
/// Modifier views copy it before passing it to their content; render groups
/// flow back up, so no state escapes a subtree.
public struct HUDRenderContext {
    /// Loaded bitmap fonts, keyed by face name (from `ResourceManager.fonts`).
    /// Needed at layout time because `Text` measures with glyph metrics.
    public var fonts: [String: BitmapFont]
    public var fillColor: Color
    /// The bitmap font face name `Text` uses when none is given explicitly.
    public var font: String?
    public var opacity: Double

    public init(
        fonts: [String: BitmapFont] = [:],
        fillColor: Color = .white,
        font: String? = nil,
        opacity: Double = 1
    ) {
        self.fonts = fonts
        self.fillColor = fillColor
        self.font = font
        self.opacity = opacity
    }
}
