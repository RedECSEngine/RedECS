/// Produces one span of views per element of a collection. `ForEach` is
/// *transparent to layout*: it does not resolve or size anything itself and
/// owns no axis — it expands, at build time, into the enclosing container's
/// child list, and that container (an `HStack`, `VStack`, …) lays the items
/// out exactly as if they had been written inline. This is why it needn't
/// know the layout direction: it never proposes a size to a parent.
///
/// What it *does* contribute is identity. Each element's views are tagged
/// with the element's stable id, so a child's animation state and input
/// tracking are keyed by *which element* it is, not its position — surviving
/// insert, reorder, and delete. (A positional key would reassign every slot
/// below an edit.) The same id-based identity is what a future lazy or
/// scrolling container will need to keep state across realization.
public struct ForEach {
    /// The element views, each already tagged with its element identity;
    /// the builder splices these into the parent's child list.
    let expanded: [AnyHUDView]

    /// Explicit-id form: identify each element by a `Hashable` value read
    /// through `id`. Use when elements aren't `Identifiable`.
    public init<Data: Collection, ID: Hashable>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @HUDViewBuilder content: (Data.Element) -> [AnyHUDView]
    ) {
        self.expanded = Self.expand(data, content: content) { $0[keyPath: id] }
    }

    /// `Identifiable` form: identify each element by its own `id`.
    public init<Data: Collection>(
        _ data: Data,
        @HUDViewBuilder content: (Data.Element) -> [AnyHUDView]
    ) where Data.Element: Identifiable {
        self.expanded = Self.expand(data, content: content) { $0.id }
    }

    private static func expand<Data: Collection, ID: Hashable>(
        _ data: Data,
        content: (Data.Element) -> [AnyHUDView],
        id: (Data.Element) -> ID
    ) -> [AnyHUDView] {
        data.flatMap { element -> [AnyHUDView] in
            let elementID = id(element)
            // An element may expand to several views; pair the element id
            // with a sub-index so each gets a distinct — but still
            // element-stable — identity.
            return content(element).enumerated().map { subIndex, view in
                view.identified(by: ElementIdentity(id: elementID, subIndex: subIndex))
            }
        }
    }

    /// Composite identity for one produced view: the element's id plus its
    /// position within that element's content. Stable under collection edits
    /// because it never encodes the element's index in the collection.
    private struct ElementIdentity<ID: Hashable>: Hashable {
        let id: ID
        let subIndex: Int
    }
}
