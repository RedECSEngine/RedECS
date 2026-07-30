import Geometry
import GeometryAlgorithms
import RedECS

/// The scroll viewport a `ScrollView` publishes to its content so a lazy
/// container can window: the current scroll `offset` and the visible `viewport`
/// size, both in the content's own coordinate space (the lazy container is the
/// scroll's content, so its origin is 0 and its visible band is
/// `[offset, offset + viewport]` on the scroll axis).
public struct ScrollWindow {
    public var offset: Point
    public var viewport: Size
    public init(offset: Point, viewport: Size) {
        self.offset = offset
        self.viewport = viewport
    }
}

/// Environment values flowing down the view tree during layout and rendering.
/// Modifier views copy it before passing it to their content; render groups
/// flow back up, so no state escapes a subtree.
public struct HUDRenderContext {
    public var resourceManager: ResourceManager?
    public var fillColor: Color
    /// The bitmap font face name `Text` uses when none is given explicitly.
    public var font: String?
    /// The point size `Text` renders at; nil renders at the font's native size.
    public var fontSize: Double?
    public var opacity: Double
    
    /// The projection each leaf stamps onto the `RenderGroup`s it emits.
    /// Read-only to callers: the only way to change it is `enteringWorldSpace()`,
    /// which also hands back the required y-flip — so a subtree can never end
    /// up in `.world` without the flip that keeps it upright.
    public private(set) var projectionSpace: RenderGroup.ProjectionSpace = .screen

    /// The active animation transaction, set by `.animated`; animatable
    /// modifiers below it ease their values through cache slots.
    var animation: HUDAnimation?
    /// Persistent per-HUD storage (animation slots); wired by the reducer.
    var cache: HUDCache?
    /// Structural identity of the view being resolved — containers append a
    /// token per child as they descend (`.index` positionally, `.id` for
    /// `ForEach` elements). Keys animation slots and pressed/hovered tracking.
    var identityPath: [IdentityToken] = []
    /// Frame time from `reduce(delta:)`; advances animation slots.
    var delta: Double = 0
    /// The scroll viewport the content is being resolved into, published by
    /// `ScrollView` when resolving its child. A lazy container (`LazyVStack`)
    /// reads it to realize only the rows intersecting the visible window; nil
    /// outside a scroll (a lazy container then falls back to realizing all).
    var scrollWindow: ScrollWindow?

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

    /// Crosses the screen→world boundary for a subtree, binding its two
    /// facets so they cannot drift: it switches `projectionSpace` to `.world`
    /// (so the subtree's leaves stamp their groups `.world`) and returns the
    /// y-flip that a y-down layout needs to render upright under the y-up world
    /// projection. Exit is implicit — the caller keeps its own context by value
    /// semantics, so the transition never escapes the subtree.
    func enteringWorldSpace() -> (context: HUDRenderContext, flip: Matrix3) {
        var world = self
        world.projectionSpace = .world
        return (world, Matrix3.identity.scaledBy(sx: 1, sy: -1))
    }

    /// The context for resolving a child, appending its identity `token` to
    /// the path that keys animation slots and input tracking.
    func descending(into token: IdentityToken) -> HUDRenderContext {
        var context = self
        context.identityPath.append(token)
        return context
    }

    /// Convenience for the common positional case.
    func descending(into index: Int) -> HUDRenderContext {
        descending(into: .index(index))
    }
}
