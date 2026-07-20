import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class HUDViewBuilderTests: XCTestCase {
    private func build(@HUDViewBuilder _ content: () -> [AnyHUDView]) -> [AnyHUDView] {
        content()
    }

    func testBuildBlockCollectsChildren() {
        let views = build {
            Rectangle()
            Rectangle()
            Rectangle()
        }
        XCTAssertEqual(views.count, 3)
    }

    func testBuildOptional() {
        let include = false
        let views = build {
            Rectangle()
            if include {
                Rectangle()
            }
        }
        XCTAssertEqual(views.count, 1)
    }

    func testBuildEither() {
        let flag = true
        let views = build {
            if flag {
                Rectangle()
            } else {
                Rectangle().foregroundColor(.red)
            }
        }
        XCTAssertEqual(views.count, 1)
    }

    func testBuildArray() {
        let views = build {
            for _ in 0..<4 {
                Rectangle()
            }
        }
        XCTAssertEqual(views.count, 4)
    }

    func testAnyHUDViewDoesNotDoubleWrap() {
        let erased = AnyHUDView(Rectangle())
        let context = HUDRenderContext()
        let size = AnyHUDView(erased).size(
            proposed: ProposedSize(width: 30, height: 40),
            context: context
        )
        XCTAssertEqual(size, Size(width: 30, height: 40))
    }

    func testRectangleDefaultSizeAndFill() {
        let rect = Rectangle()
        let context = HUDRenderContext()
        XCTAssertEqual(
            rect.size(proposed: ProposedSize(), context: context),
            Size(width: 100, height: 100)   // unproposed → ProposedSize.orDefault (100)
        )
        let groups = rect.render(context: context, size: Size(width: 10, height: 10))
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].triangles.count, 2)
        XCTAssertEqual(groups[0].color, .white)
    }

    func testForegroundColorFlowsDown() {
        let view = Rectangle().foregroundColor(.blue)
        let groups = view.render(
            context: HUDRenderContext(),
            size: Size(width: 10, height: 10)
        )
        XCTAssertEqual(groups.first?.color, .blue)
    }
}
