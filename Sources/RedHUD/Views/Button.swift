import Geometry
import RedECS

/// The button's live interaction state, derived from the cache's pressed
/// and hovered identities — style content with it and pair with `.animated`
/// for transitions:
///
///     Button(up: GameAction.pausePressed) { interaction in
///         Text("Pause")
///             .scaleEffect(interaction.isPressed ? 1.15 : 1.0)
///             .animated(duration: 0.12, timing: .easeOut)
///     }
public struct ButtonInteraction: Equatable, Sendable {
    public var isPressed: Bool
    public var isHovered: Bool
}

/// Wraps content with interaction payloads: `down` fires on press, `up` on
/// release over the same button the press started on, `hover` once on
/// pointer entry. All are game-action values, type-erased internally; the
/// reducer casts back to its `GameAction` (a mismatched type asserts in
/// debug and no-ops in release). Draws no chrome of its own.
public struct Button<Content: HUDView>: BuiltinHUDView {
    var down: Any?
    var up: Any?
    var hover: Any?
    let content: (ButtonInteraction) -> Content

    init(down: Any?, up: Any?, hover: Any?, resolvedContent: @escaping (ButtonInteraction) -> Content) {
        self.down = down
        self.up = up
        self.hover = hover
        self.content = resolvedContent
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        let interaction = ButtonInteraction(
            isPressed: context.cache?.pressedIdentity == context.identityPath,
            isHovered: context.cache?.hoveredIdentity == context.identityPath
        )
        var node = content(interaction)._resolve(proposed: proposed, context: context)
        node.hit = ButtonHit(down: down, up: up, hover: hover)
        return node
    }
}

public extension Button {
    /// At least one action must be given (the generic is inferred from it);
    /// an actionless button has no reason to exist.
    init<A: Equatable>(
        down: A? = nil,
        up: A? = nil,
        hover: A? = nil,
        @HUDViewBuilder content: @escaping (ButtonInteraction) -> [AnyHUDView]
    ) where Content == AnyHUDView {
        self.init(
            down: down,
            up: up,
            hover: hover,
            resolvedContent: { interaction in
                AnyHUDView.wrapping(content(interaction))
            }
        )
    }

    init<A: Equatable>(
        down: A? = nil,
        up: A? = nil,
        hover: A? = nil,
        @HUDViewBuilder content: @escaping () -> [AnyHUDView]
    ) where Content == AnyHUDView {
        self.init(down: down, up: up, hover: hover) { _ in content() }
    }
}

extension AnyHUDView {
    /// Builder output as one view: a single child directly, several in an
    /// implicit VStack (mirroring `Pin`), none an empty node.
    static func wrapping(_ views: [AnyHUDView]) -> AnyHUDView {
        if views.count == 1 {
            return views[0]
        }
        return AnyHUDView(VStack { views })
    }
}
