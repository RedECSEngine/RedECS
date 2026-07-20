import XCTest
import Geometry
import RedECS
@testable import RedHUD

/// The cheap `size()` overrides must equal `resolve(...).frame.size` — the
/// layout invariant that lets `LazyVStack` measure without drawing. This
/// exercises the covered views (leaves, stacks, frame, padding, overlay,
/// render-only modifiers, button) individually and nested.
final class SizeInvariantTests: XCTestCase {
    private let context = HUDRenderContext()

    private func assertMatches(_ view: AnyHUDView, _ label: String,
                               _ proposed: ProposedSize = ProposedSize(width: 200, height: 200),
                               file: StaticString = #filePath, line: UInt = #line) {
        let cheap = view.size(proposed: proposed, context: context)
        let resolved = view._resolve(proposed: proposed, context: context).frame.size
        XCTAssertEqual(cheap, resolved, "\(label): size() must equal resolve().frame.size",
                       file: file, line: line)
    }

    func testCoveredViews() {
        assertMatches(AnyHUDView(Rectangle()), "flexible rect")
        assertMatches(AnyHUDView(Rectangle().frame(width: 40, height: 20)), "fixed frame")
        assertMatches(AnyHUDView(Rectangle().frame(width: 30, height: 30).padding(6)), "padding")
        assertMatches(AnyHUDView(Rectangle().frame(width: 40, height: 40).scaleEffect(2)), "scaleEffect")
        assertMatches(AnyHUDView(Rectangle().frame(width: 40, height: 40).opacity(0.5)), "opacity")
        assertMatches(AnyHUDView(Rectangle().frame(width: 40, height: 40).foregroundColor(.red)), "foregroundColor")
        assertMatches(
            AnyHUDView(Rectangle().frame(width: 60, height: 40).overlay { Rectangle().frame(width: 200, height: 200) }),
            "overlay (base size)")
        assertMatches(
            AnyHUDView(Button(up: "x") { Rectangle().frame(width: 50, height: 30) }),
            "button")
        assertMatches(
            AnyHUDView(VStack(spacing: 8) {
                Rectangle().frame(width: 30, height: 10)
                Rectangle().frame(width: 50, height: 40)
            }), "vstack")
        assertMatches(
            AnyHUDView(HStack(spacing: 4) {
                Rectangle().frame(width: 30, height: 10)
                Rectangle().frame(width: 20, height: 40)
            }), "hstack")
        assertMatches(
            AnyHUDView(ZStack {
                Rectangle().frame(width: 100, height: 60)
                Rectangle().frame(width: 40, height: 90)
            }), "zstack")
    }

    func testNestedComposition() {
        assertMatches(
            AnyHUDView(
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Rectangle().frame(width: 20, height: 20)
                        Rectangle().frame(width: 40, height: 30).padding(3)
                    }
                    ZStack {
                        Rectangle().frame(width: 80, height: 50)
                        Rectangle().frame(width: 20, height: 20).scaleEffect(1.5)
                    }
                    Button(up: "y") { Rectangle().frame(width: 60, height: 24) }
                }
            ), "nested tree")
    }
}
