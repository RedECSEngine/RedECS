import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class ButtonTests: XCTestCase {
    private var renderer: FakeRenderer!
    private var environment: FakeEnvironment!
    private var state = TestState()

    /// Two 40x40 buttons side by side, centered in the 480x320 viewport:
    /// root is 80x40 at (200, 140) — button A spans x 200..<240,
    /// button B x 240..<280, both y 140..<180.
    private var reducer: HUDRenderingReducer<TestState, String>!

    override func setUp() {
        renderer = FakeRenderer()
        environment = FakeEnvironment(fakeRenderer: renderer)
        state = TestState()
        reducer = HUDRenderingReducer<TestState, String> { _ in
            AnyHUDView(HStack {
                Button(down: "a-down", up: "a-up", hover: "a-hover") {
                    Rectangle().frame(width: 40, height: 40)
                }
                Button(up: "b-up") {
                    Rectangle().frame(width: 40, height: 40)
                }
            })
        }
        drawFrame()
    }

    private func drawFrame() {
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
    }

    private func send(_ action: HUDAction<String>) -> String? {
        let effect = reducer.reduce(state: &state, action: action, environment: environment)
        if case .game(.triggered(let fired)) = effect {
            return fired
        }
        return nil
    }

    let insideA = Point(x: 220, y: 160)
    let insideB = Point(x: 260, y: 160)
    let outside = Point(x: 10, y: 10)

    func testDownFiresDownAction() {
        XCTAssertEqual(send(.pointerDown(insideA)), "a-down")
    }

    func testUpFiresOnlyAfterDownOnSameButton() {
        _ = send(.pointerDown(insideA))
        XCTAssertEqual(send(.pointerUp(insideA)), "a-up")
    }

    func testUpWithoutDownDoesNotFire() {
        XCTAssertNil(send(.pointerUp(insideA)))
    }

    func testDragOffToAnotherButtonDoesNotFire() {
        _ = send(.pointerDown(insideA))
        XCTAssertNil(send(.pointerUp(insideB)))
        // and the press is consumed — a later up on A fires nothing
        XCTAssertNil(send(.pointerUp(insideA)))
    }

    func testReleaseOutsideConsumesPress() {
        _ = send(.pointerDown(insideA))
        XCTAssertNil(send(.pointerUp(outside)))
        XCTAssertNil(send(.pointerUp(insideA)))
    }

    func testHoverFiresOnEntryOnly() {
        XCTAssertEqual(send(.pointerMove(insideA)), "a-hover")
        XCTAssertNil(send(.pointerMove(Point(x: 221, y: 161))))   // still inside
        XCTAssertNil(send(.pointerMove(outside)))                 // exit is silent
        XCTAssertEqual(send(.pointerMove(insideA)), "a-hover")    // re-entry fires
    }

    func testCrossingBetweenButtonsChangesHoverIdentity() {
        XCTAssertEqual(send(.pointerMove(insideA)), "a-hover")
        // B has no hover action: entry is silent but identity updates,
        // so returning to A fires again
        XCTAssertNil(send(.pointerMove(insideB)))
        XCTAssertEqual(send(.pointerMove(insideA)), "a-hover")
    }

    func testButtonWithoutDownActionStillTracksPress() {
        XCTAssertNil(send(.pointerDown(insideB)))    // no down action
        XCTAssertEqual(send(.pointerUp(insideB)), "b-up")
    }

    func testHiddenHUDSwallowsPointerEvents() {
        reducer.cache.clear()
        XCTAssertNil(send(.pointerDown(insideA)))
        XCTAssertNil(send(.pointerUp(insideA)))
    }

    func testInteractionClosureSeesPressedState() {
        let styled = HUDRenderingReducer<TestState, String> { _ in
            AnyHUDView(Button(up: "tap") { interaction in
                Rectangle()
                    .frame(width: 40, height: 40)
                    .foregroundColor(interaction.isPressed ? .yellow : .white)
            })
        }
        _ = styled.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertEqual(renderer.queuedWork.last?.color, .white)

        _ = styled.reduce(state: &state, action: .pointerDown(Point(x: 240, y: 160)), environment: environment)
        renderer.queuedWork.removeAll()
        _ = styled.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertEqual(renderer.queuedWork.last?.color, .yellow)

        _ = styled.reduce(state: &state, action: .pointerUp(Point(x: 240, y: 160)), environment: environment)
        renderer.queuedWork.removeAll()
        _ = styled.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertEqual(renderer.queuedWork.last?.color, .white)
    }
}
