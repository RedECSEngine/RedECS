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

    func clear() {
        lastTree = nil
        lastViewport = .zero
        lastRootOffset = .zero
        animationSlots.removeAll()
        spriteClocks.removeAll()
        touchedAnimationKeys.removeAll()
        pressedIdentity = nil
        hoveredIdentity = nil
    }
}
