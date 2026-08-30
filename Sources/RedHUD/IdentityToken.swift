/// One step of a view's structural identity. Containers append a token per
/// level as they descend, forming the `identityPath` that keys animation
/// slots and pressed/hovered tracking.
///
/// Most containers key children by position (`.index`); `ForEach` keys them
/// by the element's stable id (`.id`) so a child's animation state and input
/// tracking survive insert, reorder, and delete — the index-based path would
/// reassign every slot below an edit. The same stability is what a future
/// lazy/scrolling container needs to keep identity across realization.
public enum IdentityToken: Hashable {
    case index(Int)
    case id(AnyHashable)
}
