import Geometry
import RedECS

/// A vertically-stacked, data-driven list that realizes only the rows visible
/// in its enclosing `ScrollView` — the lazy content for `ScrollView { LazyVStack { … } }`.
///
/// It is genuinely lazy: every frame it **measures** all rows with the cheap,
/// side-effect-free `size` path (no render groups, no cache), giving exact row
/// positions and total height, then **builds/draws only the rows intersecting
/// the visible window**. Off-screen rows are never resolved, so a huge list
/// costs O(rows) cheap measurements + O(visible) real work per frame — no
/// estimation, no scroll drift. Each realized row resolves under its element
/// `id`, so a row scrolled off and back keeps its animation state.
///
/// Rows may be arbitrary HUDViews of differing heights. Outside a `ScrollView`
/// (no published window) it falls back to realizing every row.
public struct LazyVStack<Data: RandomAccessCollection, ID: Hashable>: BuiltinHUDView {
    public var data: Data
    public var id: KeyPath<Data.Element, ID>
    public var alignment: HorizontalAlignment
    public var spacing: Double
    public var row: (Data.Element) -> AnyHUDView

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        alignment: HorizontalAlignment = .center,
        spacing: Double = 0,
        @HUDViewBuilder row: @escaping (Data.Element) -> [AnyHUDView]
    ) {
        self.data = data
        self.id = id
        self.alignment = alignment
        self.spacing = spacing
        self.row = { AnyHUDView.wrapping(row($0)) }
    }

    /// Builds every row view and measures it cheaply (cache-less, so measuring
    /// off-screen rows never touches animation slots), returning exact per-row
    /// offsets/heights and the total height — the shared layout pass for both
    /// `size` (measure only) and `resolve` (measure + build the window).
    private func measure(width: Double, context: HUDRenderContext)
        -> (elements: [Data.Element], rowViews: [AnyHUDView], offsets: [Double], heights: [Double], total: Double) {
        let elements = Array(data)
        let rowViews = elements.map { row($0) }
        var measureContext = context
        measureContext.cache = nil
        var offsets: [Double] = []
        offsets.reserveCapacity(rowViews.count)
        var heights: [Double] = []
        heights.reserveCapacity(rowViews.count)
        var y: Double = 0
        for view in rowViews {
            let h = view.size(proposed: ProposedSize(width: width, height: nil), context: measureContext).height
            offsets.append(y)
            heights.append(h)
            y += h + spacing
        }
        let total = rowViews.isEmpty ? 0 : y - spacing
        return (elements, rowViews, offsets, heights, total)
    }

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        // Measure-only: the exact total height, without building any rows.
        let width = proposed.orDefault().width
        return Size(width: width, height: measure(width: width, context: context).total)
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        let width = proposed.orDefault().width
        let (elements, rowViews, offsets, heights, totalHeight) = measure(width: width, context: context)

        // Realize only the rows intersecting the enclosing scroll window
        // (all rows when not scrolled).
        let window = context.scrollWindow
        var placed: [HUDNode] = []
        for index in rowViews.indices {
            let top = offsets[index]
            let bottom = top + heights[index]
            if let window = window {
                let visibleTop = window.offset.y
                let visibleBottom = visibleTop + window.viewport.height
                guard bottom >= visibleTop && top <= visibleBottom else { continue }
            }
            let rowID = elements[index][keyPath: id]
            var node = rowViews[index].resolve(
                proposed: ProposedSize(width: width, height: nil),
                context: context.descending(into: .id(rowID))
            )
            node.frame.origin = Point(
                x: alignment.value(in: width) - alignment.value(in: node.frame.size.width),
                y: top
            )
            placed.append(node)
        }

        return HUDNode(
            frame: Rect(origin: .zero, size: Size(width: width, height: totalHeight)),
            children: placed
        )
    }
}
