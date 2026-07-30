import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class LazyVStackTests: XCTestCase {
    private func resolve(offsetY: Double, viewportH: Double) -> HUDNode {
        var context = HUDRenderContext()
        context.cache = HUDCache()
        context.scrollWindow = ScrollWindow(
            offset: Point(x: 0, y: offsetY),
            viewport: Size(width: 200, height: viewportH)
        )
        let view = LazyVStack(0..<1000, id: \.self) { _ in
            Rectangle().frame(width: 200, height: 40)
        }
        return view._resolve(proposed: ProposedSize(width: 200, height: viewportH), context: context)
    }

    func testReportsExactTotalHeightWithoutRealizingAll() {
        let node = resolve(offsetY: 0, viewportH: 200)
        // 1000 rows × 40 = exact total, measured cheaply.
        XCTAssertEqual(node.frame.size.height, 40_000, accuracy: 0.001)
        // Only the visible window (~5 rows) is realized, not 1000.
        XCTAssertLessThan(node.children.count, 10)
        XCTAssertEqual(node.children.first?.frame.origin.y ?? -1, 0, accuracy: 0.001)
    }

    func testWindowShiftsWithScrollOffset() {
        let node = resolve(offsetY: 400, viewportH: 200)
        // Scrolled to y=400: rows ~9–15 are realized, still a small window.
        XCTAssertLessThan(node.children.count, 10)
        let firstY = node.children.first?.frame.origin.y ?? -1
        XCTAssertGreaterThanOrEqual(firstY, 360)   // row 9 (bottom == 400) or later
        XCTAssertLessThanOrEqual(firstY, 400)
        // Total height is unchanged and exact.
        XCTAssertEqual(node.frame.size.height, 40_000, accuracy: 0.001)
    }

    func testRealizesAllWhenNotInAScroll() {
        // No scrollWindow published → eager fallback (a small list here).
        var context = HUDRenderContext()
        context.cache = HUDCache()
        let view = LazyVStack(0..<6, id: \.self) { _ in Rectangle().frame(width: 100, height: 20) }
        let node = view._resolve(proposed: ProposedSize(width: 100, height: 200), context: context)
        XCTAssertEqual(node.children.count, 6)
        XCTAssertEqual(node.frame.size.height, 120, accuracy: 0.001)
    }
}
