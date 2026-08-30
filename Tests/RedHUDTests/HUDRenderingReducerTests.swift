import XCTest
import Geometry
import GeometryAlgorithms
import RedECS
import TiledInterpreter
@testable import RedHUD

final class HUDRenderingReducerTests: XCTestCase {
    private var renderer: FakeRenderer!
    private var environment: FakeEnvironment!
    private var state = TestState()

    override func setUp() {
        renderer = FakeRenderer()
        environment = FakeEnvironment(fakeRenderer: renderer)
        state = TestState()
    }

    func testNilContentRendersNothing() {
        let reducer = HUDRenderingReducer<TestState, Never> { _ in nil }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertTrue(renderer.queuedWork.isEmpty)
    }

    func testContentDerivesFromState() {
        let reducer = HUDRenderingReducer<TestState, Never> { state in
            state.score > 0
                ? AnyHUDView(Rectangle().frame(width: 10, height: 10))
                : nil
        }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertTrue(renderer.queuedWork.isEmpty)

        state.score = 5
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertEqual(renderer.queuedWork.count, 1)
    }

    func testGroupsAreScreenSpaceInPaintOrderAndCentered() {
        let reducer = HUDRenderingReducer<TestState, Never> { _ in
            AnyHUDView(HStack {
                Rectangle().frame(width: 20, height: 10)
                Rectangle().frame(width: 20, height: 10)
            })
        }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)

        XCTAssertEqual(renderer.queuedWork.count, 2)
        for (i, group) in renderer.queuedWork.enumerated() {
            // z is offset by the default baseZIndex (1000) so HUD paints above
            // the scene; paint order is preserved within that base.
            XCTAssertEqual(group.zIndex, 1000 + i)
            if case .world = group.projectionSpace {
                XCTFail("HUD groups must be screen-space")
            }
        }
        // A 40x10 root centered in 480x320 starts at (220, 155).
        let firstOrigin = Point.zero.multiplyingMatrix(renderer.queuedWork[0].transformMatrix)
        XCTAssertEqual(firstOrigin, Point(x: 220, y: 155))
    }

    func testCacheRetainsLastDrawnTree() {
        let reducer = HUDRenderingReducer<TestState, Never> { _ in
            AnyHUDView(Rectangle().frame(width: 40, height: 10))
        }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)

        XCTAssertNotNil(reducer.cache.lastTree)
        XCTAssertEqual(reducer.cache.lastViewport, Size(width: 480, height: 320))
        // 40x10 root centered in 480x320
        XCTAssertEqual(reducer.cache.lastRootOffset, Point(x: 220, y: 155))
        XCTAssertEqual(reducer.cache.lastTree?.frame.size, Size(width: 40, height: 10))
    }

    func testCacheClearsWhenContentHides() {
        var visible = true
        let reducer = HUDRenderingReducer<TestState, Never> { _ in
            visible ? AnyHUDView(Rectangle()) : nil
        }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertNotNil(reducer.cache.lastTree)

        visible = false
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertNil(reducer.cache.lastTree, "a hidden HUD must not retain hit geometry")
    }

    func testZeroViewportRendersNothing() {
        renderer.viewportSize = .zero
        let reducer = HUDRenderingReducer<TestState, Never> { _ in
            AnyHUDView(Rectangle())
        }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertTrue(renderer.queuedWork.isEmpty)
    }
}
