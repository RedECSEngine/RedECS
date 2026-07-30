import XCTest
import Geometry
import RedECS
@testable import RedHUD

/// Drag-scroll behaviour driven through the reducer with synthetic pointer
/// events (no platform input needed). A 200x100 ScrollView is centered in the
/// 480x320 viewport, so its window spans screen (140,110)…(340,210); content is
/// 600pt tall (maxOffset 500). Row 0 is a Button to prove tap-vs-drag.
final class ScrollDragTests: XCTestCase {
    private var renderer: FakeRenderer!
    private var environment: FakeEnvironment!
    private var state = TestState()
    private var reducer: HUDRenderingReducer<TestState, String>!

    override func setUp() {
        renderer = FakeRenderer()
        environment = FakeEnvironment(fakeRenderer: renderer)
        state = TestState()
        reducer = HUDRenderingReducer<TestState, String> { _ in
            AnyHUDView(
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        Button(up: "row0") { Rectangle().frame(width: 200, height: 60) }
                        ForEach(1..<10, id: \.self) { _ in
                            Rectangle().frame(width: 200, height: 60)
                        }
                    }
                }
                .frame(width: 200, height: 100)
            )
        }
        drawFrame()
    }

    private func drawFrame() { _ = reducer.reduce(state: &state, delta: 1, environment: environment) }
    @discardableResult private func send(_ a: HUDAction<String>) -> String? {
        if case .game(.triggered(let f)) = reducer.reduce(state: &state, action: a, environment: environment) { return f }
        return nil
    }
    private var offset: Double { reducer.cache.scrollSlots.values.first?.offset.y ?? .nan }

    private let inside = Point(x: 240, y: 160)   // middle of the window

    func testDragAccumulatesOffset() {
        send(.pointerDown(inside))
        send(.pointerMove(Point(x: 240, y: 130)))   // up 30 → content scrolls up
        XCTAssertEqual(offset, 30, accuracy: 0.001)
        send(.pointerMove(Point(x: 240, y: 110)))   // up another 20 → 50 total
        XCTAssertEqual(offset, 50, accuracy: 0.001)
    }

    func testOffsetClampsAtTop() {
        send(.pointerDown(inside))
        send(.pointerMove(Point(x: 240, y: 300)))   // drag far down past the top
        XCTAssertEqual(offset, 0, accuracy: 0.001)   // clamped, can't scroll above content
    }

    func testDragSuppressesButtonTap() {
        // Press on row0 (the button), drag past threshold, release: no tap.
        send(.pointerDown(inside))
        send(.pointerMove(Point(x: 240, y: 140)))   // moved 20 > threshold(4)
        XCTAssertNil(send(.pointerUp(inside)))
    }

    func testTapWithoutDragStillFires() {
        // A press that doesn't move is a tap: row0's up fires. Screen (240,140)
        // → window-local (100,30), inside row0 (content y 0…60 at offset 0).
        let onRow0 = Point(x: 240, y: 140)
        send(.pointerDown(onRow0))
        XCTAssertEqual(send(.pointerUp(onRow0)), "row0")
    }

    func testPressOverContentCapturesScrollRegion() {
        // Down anywhere in the window starts a drag capture even off a button.
        send(.pointerDown(inside))
        XCTAssertNotNil(reducer.cache.activeScroll)
    }
}
