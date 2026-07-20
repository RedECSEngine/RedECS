import Geometry
import RedECS

/// A clipping, draggable viewport over content taller (or wider) than itself.
/// Content is laid out at its natural length along the scroll axis, offset by
/// the current scroll amount, and clipped to the ScrollView's frame. The
/// offset persists in the cache (keyed by identity) and is driven by drag
/// (see the reducer) or by `scrollTo`.
///
/// `scrollTo` is declarative and edge-triggered like `.change(of:)`: pass an
/// element id derived from state and, when it changes, the ScrollView scrolls
/// that element into view. There is no imperative proxy — RedHUD is `f(state)`,
/// so a scroll target is just more state.
///
///     ScrollView(.vertical, scrollTo: state.focusedRowID) {
///         VStack(spacing: 8) { ForEach(rows, id: \.id) { RowView($0) } }
///     }
public struct ScrollView: BuiltinHUDView {
    public var axis: ScrollAxis
    public var scrollTo: AnyHashable?
    public var content: AnyHUDView

    public init(
        _ axis: ScrollAxis = .vertical,
        scrollTo: AnyHashable? = nil,
        @HUDViewBuilder content: () -> [AnyHUDView]
    ) {
        self.axis = axis
        self.scrollTo = scrollTo
        self.content = AnyHUDView.wrapping(content())
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        let window = proposed.orDefault()
        // Propose the cross axis; leave the scroll axis unbounded so content
        // takes its ideal length.
        let contentProposal = axis == .vertical
            ? ProposedSize(width: window.width, height: nil)
            : ProposedSize(width: nil, height: window.height)
        var content = content.resolve(proposed: contentProposal, context: context.descending(into: 0))

        let contentExtent = axis == .vertical ? content.frame.size.height : content.frame.size.width
        let windowExtent = axis == .vertical ? window.height : window.width
        let maxOffset = max(0, contentExtent - windowExtent)

        var slot = context.cache?.scrollSlot(for: context.identityPath) ?? ScrollState()
        slot.axis = axis
        slot.range = 0...maxOffset

        // Declarative scrollTo: edge-triggered on target change.
        if let target = scrollTo, slot.lastTarget != target {
            if let itemOffset = content.scrollOffset(along: axis, matching: target) {
                slot.setOffset(itemOffset.clamped(to: slot.range), along: axis)
            }
            slot.lastTarget = target
        }

        // Content may have shrunk since the last drag; keep the offset valid.
        slot.setOffset(slot.offset(along: axis).clamped(to: slot.range), along: axis)
        context.cache?.setScrollSlot(slot, for: context.identityPath)

        // Place content by frame.origin (layout translate) so render AND hit
        // geometry both move with the scroll; the window frame gates hits and
        // the clip gates drawing.
        let o = slot.offset(along: axis)
        content.frame.origin = axis == .vertical ? Point(x: 0, y: -o) : Point(x: -o, y: 0)

        var node = HUDNode(frame: Rect(origin: .zero, size: window), children: [content])
        node.clip = Rect(origin: .zero, size: window)
        node.scroll = ScrollRegion(axis: axis)
        return node
    }
}

extension HUDNode {
    /// The cumulative offset (along `axis`, in this node's local space) of the
    /// first descendant identified by `target` — directly (`.id(target)`) or as
    /// a `ForEach` element. Used by `scrollTo` to turn an id into an offset.
    func scrollOffset(along axis: ScrollAxis, matching target: AnyHashable) -> Double? {
        func extent(_ origin: Point) -> Double { axis == .horizontal ? origin.x : origin.y }
        func search(_ node: HUDNode, acc: Double) -> Double? {
            let here = acc + extent(node.frame.origin)
            if let last = node.identity.last, last.matches(target) { return here }
            for child in node.children {
                if let found = search(child, acc: here) { return found }
            }
            return nil
        }
        // Start children at acc 0; `search` adds each node's own origin,
        // including the first level, so the content root's origin is excluded.
        for child in children {
            if let found = search(child, acc: 0) { return found }
        }
        return nil
    }
}

extension IdentityToken {
    /// Whether this token identifies `target`, matching either a direct
    /// `.id(target)` or a `ForEach` element whose id equals `target`.
    func matches(_ target: AnyHashable) -> Bool {
        guard case let .id(value) = self else { return false }
        if value == target { return true }
        if let element = value.base as? ForEachElementIdentifiable {
            return element.forEachElementID == target
        }
        return false
    }
}
