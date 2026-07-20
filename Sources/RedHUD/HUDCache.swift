import Geometry

/// Transient per-HUD storage that persists across frames. The reducer holds
/// one instance for its lifetime (reducers live in the GameStore for the
/// app's life), so this is where anything that must outlive a single
/// resolve pass lives — the last drawn tree for hit testing, and, in later
/// milestones, pressed/hovered identities and animation slots. Deliberately
/// a reference type outside GameState: never encoded, diffed, or replayed.
final class HUDCache {
    /// The most recently resolved (and therefore drawn) tree; pointer
    /// events hit-test against this, so input lands on what the player is
    /// actually seeing. Nil whenever nothing was drawn — a hidden HUD
    /// cannot claim input.
    var lastTree: HUDNode?
    var lastViewport: Size = .zero
    /// The centering offset applied to the root at emit time; pointer
    /// points are translated by its inverse before walking the tree.
    var lastRootOffset: Point = .zero

    /// Tween state for animatable modifiers, keyed by tree position; pruned
    /// each frame to the modifiers that actually resolved.
    var animationSlots: [AnimationKey: AnimationSlot] = [:]
    /// Playheads for self-clocked `Sprite`s, keyed and pruned the same way.
    var spriteClocks: [AnimationKey: Double] = [:]
    var touchedAnimationKeys: Set<AnimationKey> = []

    /// The button the pointer went down on; its `up` action fires only if
    /// the release lands on the same button.
    var pressedIdentity: [IdentityToken]?
    /// The button currently under the pointer; hover fires on entry only.
    var hoveredIdentity: [IdentityToken]?

    /// Per-`ScrollView` state, keyed by identity like `animationSlots`, pruned
    /// each frame to the scroll regions that actually resolved.
    var scrollSlots: [[IdentityToken]: ScrollState] = [:]
    var touchedScrollKeys: Set<[IdentityToken]> = []
    /// The scroll region a drag is currently captured to (set on `pointerDown`
    /// over a scroll region, cleared on `pointerUp`), with the last pointer
    /// position and total travel so a drag can be told from a tap.
    var activeScroll: (identity: [IdentityToken], lastPoint: Point, moved: Double)?

    /// Reads a scroll slot (installing a default) and marks it touched so it
    /// survives this frame's prune. Mirrors the animation-slot access pattern.
    func scrollSlot(for identity: [IdentityToken]) -> ScrollState {
        touchedScrollKeys.insert(identity)
        return scrollSlots[identity] ?? ScrollState()
    }

    func setScrollSlot(_ state: ScrollState, for identity: [IdentityToken]) {
        scrollSlots[identity] = state
    }

    func beginScrollFrame() { touchedScrollKeys.removeAll(keepingCapacity: true) }

    /// Drops slots whose scroll regions didn't resolve this frame.
    func endScrollFrame() {
        scrollSlots = scrollSlots.filter { touchedScrollKeys.contains($0.key) }
    }

    func clear() {
        lastTree = nil
        lastViewport = .zero
        lastRootOffset = .zero
        animationSlots.removeAll()
        spriteClocks.removeAll()
        touchedAnimationKeys.removeAll()
        pressedIdentity = nil
        hoveredIdentity = nil
        scrollSlots.removeAll()
        touchedScrollKeys.removeAll()
        activeScroll = nil
    }
}

/// Persistent state for one `ScrollView`, evolving across frames in the cache.
struct ScrollState {
    /// Which axis this scroll region scrolls along; written by the view so the
    /// reducer's drag handler knows how to interpret pointer deltas.
    var axis: ScrollAxis = .vertical
    /// Current scroll offset; content is shifted by `-offset`.
    var offset: Point = .zero
    /// Valid offset range along the scroll axis, written each frame by the
    /// view from the freshest content size, so drag/momentum clamp correctly.
    var range: ClosedRange<Double> = 0...0
    /// Per-frame scroll velocity (points/frame), seeded from drag deltas and
    /// decayed for momentum (Phase 2).
    var velocity: Double = 0
    /// The last `scrollTo` target handled, so it is edge-triggered on change
    /// (matching `.change(of:)`).
    var lastTarget: AnyHashable?

    func offset(along axis: ScrollAxis) -> Double {
        axis == .horizontal ? offset.x : offset.y
    }

    mutating func setOffset(_ value: Double, along axis: ScrollAxis) {
        if axis == .horizontal { offset.x = value } else { offset.y = value }
    }
}
