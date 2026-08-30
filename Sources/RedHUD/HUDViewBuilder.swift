/// Result builder for HUD content. Everything erases to `[AnyHUDView]`,
/// which keeps stacks tuple-free and makes if/else/for come along for free.
@resultBuilder
public enum HUDViewBuilder {
    public static func buildExpression<V: HUDView>(_ view: V) -> [AnyHUDView] {
        [AnyHUDView(view)]
    }

    public static func buildExpression(_ views: [AnyHUDView]) -> [AnyHUDView] {
        views
    }

    /// `ForEach` is transparent: it splices its (identity-tagged) element
    /// views directly into the enclosing container's child list.
    public static func buildExpression(_ forEach: ForEach) -> [AnyHUDView] {
        forEach.expanded
    }

    public static func buildBlock(_ components: [AnyHUDView]...) -> [AnyHUDView] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [AnyHUDView]?) -> [AnyHUDView] {
        component ?? []
    }

    public static func buildEither(first component: [AnyHUDView]) -> [AnyHUDView] {
        component
    }

    public static func buildEither(second component: [AnyHUDView]) -> [AnyHUDView] {
        component
    }

    public static func buildArray(_ components: [[AnyHUDView]]) -> [AnyHUDView] {
        components.flatMap { $0 }
    }
}
