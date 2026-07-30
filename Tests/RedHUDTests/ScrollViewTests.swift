import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class ScrollViewTests: XCTestCase {
    private func resolve(_ view: ScrollView, cache: HUDCache) -> HUDNode {
        var context = HUDRenderContext()
        context.cache = cache
        cache.beginScrollFrame()
        let node = view._resolve(proposed: ProposedSize(width: 200, height: 180), context: context)
        cache.endScrollFrame()
        return node
    }

    func testScrollToResolvesElementOffset() {
        let cache = HUDCache()
        let view = ScrollView(.vertical, scrollTo: 6) {
            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { _ in Rectangle().frame(width: 200, height: 60) }
            }
        }
        let node = resolve(view, cache: cache)
        // row 6 starts at y = 360; content is placed at -360.
        XCTAssertEqual(node.children[0].frame.origin.y, -360, accuracy: 0.001)
    }

    func testOffsetClampsToContent() {
        let cache = HUDCache()
        // scrollTo the last row: its raw offset (540) exceeds max (600-180=420).
        let view = ScrollView(.vertical, scrollTo: 9) {
            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { _ in Rectangle().frame(width: 200, height: 60) }
            }
        }
        let node = resolve(view, cache: cache)
        XCTAssertEqual(node.children[0].frame.origin.y, -420, accuracy: 0.001)
    }
}
