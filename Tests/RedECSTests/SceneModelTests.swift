import XCTest
@testable import RedECS

final class SceneModelTests: XCTestCase {
    func testSceneComponentDefaultsAndCodableRoundTrip() throws {
        let component = SceneComponent(entity: "menu")
        XCTAssertFalse(component.keepAliveOnDismiss)
        XCTAssertFalse(component.cancelsPendingEffectsOnDismiss)

        let custom = SceneComponent(entity: "menu", keepAliveOnDismiss: true, cancelsPendingEffectsOnDismiss: true)
        let data = try JSONEncoder().encode(custom)
        let decoded = try JSONDecoder().decode(SceneComponent.self, from: data)
        XCTAssertEqual(decoded, custom)
    }

    func testTransitionPresets() {
        XCTAssertEqual(SceneTransition.fade(duration: 1), SceneTransition(duration: 1, phasing: .sequential, outEffect: .fade, inEffect: .fade))
        XCTAssertEqual(SceneTransition.crossFade(duration: 1), SceneTransition(duration: 1, phasing: .crossover, outEffect: .fade))
        XCTAssertEqual(SceneTransition.dissolve(duration: 1), SceneTransition(duration: 1, phasing: .crossover, outEffect: .turnOff))
        XCTAssertEqual(SceneTransition.blindsRows(duration: 1), SceneTransition(duration: 1, phasing: .sequential, outEffect: .splitRows, inEffect: .splitRows))
        XCTAssertEqual(SceneTransition.blindsCols(duration: 1), SceneTransition(duration: 1, phasing: .sequential, outEffect: .splitCols, inEffect: .splitCols))
        XCTAssertEqual(SceneTransition.shuffle(duration: 1), SceneTransition(duration: 1, phasing: .sequential, outEffect: .shuffle, inEffect: .shuffle))
    }

    func testSequentialPhasingDrawsOneSideAtATime() {
        var active = ActiveSceneTransition(
            outgoingSceneId: "a",
            incomingSceneId: "b",
            transition: .fade(duration: 2)
        )

        active.elapsed = 0.5
        XCTAssertTrue(active.drawsOutgoing)
        XCTAssertFalse(active.drawsIncoming)
        XCTAssertEqual(active.outgoingShader(), .fade(time: 0.5))

        active.elapsed = 1.5
        XCTAssertFalse(active.drawsOutgoing)
        XCTAssertTrue(active.drawsIncoming)
        XCTAssertEqual(active.incomingShader(), .fade(time: 0.5))
    }

    func testSequentialShaderTimesClampAtPhaseBoundaries() {
        var active = ActiveSceneTransition(
            outgoingSceneId: "a",
            incomingSceneId: "b",
            transition: SceneTransition(duration: 1, phasing: .sequential, outEffect: .turnOff, inEffect: .turnOff)
        )

        active.elapsed = 0.5
        XCTAssertEqual(active.incomingShader(), .turnOff(time: 0.999))

        active.elapsed = 0.999
        guard case .turnOff(let outTime)? = active.outgoingShader() else {
            return XCTFail("expected turnOff")
        }
        XCTAssertLessThanOrEqual(outTime, 0.999)

        active.elapsed = 5
        XCTAssertTrue(active.isComplete)
        guard case .turnOff(let lateInTime)? = active.incomingShader() else {
            return XCTFail("expected turnOff")
        }
        XCTAssertGreaterThanOrEqual(lateInTime, 0)
    }

    func testCrossoverPhasingDrawsBothSides() {
        var active = ActiveSceneTransition(
            outgoingSceneId: "a",
            incomingSceneId: nil,
            transition: .dissolve(duration: 1)
        )
        active.elapsed = 0.25
        XCTAssertTrue(active.drawsOutgoing)
        XCTAssertTrue(active.drawsIncoming)
        XCTAssertEqual(active.outgoingShader(), .turnOff(time: 0.25))
        XCTAssertNil(active.incomingShader())
    }

    func testZeroDurationTransitionIsCompleteAndFullyProgressed() {
        let active = ActiveSceneTransition(
            outgoingSceneId: nil,
            incomingSceneId: "b",
            transition: SceneTransition(duration: 0, phasing: .crossover, outEffect: .fade)
        )
        XCTAssertTrue(active.isComplete)
        XCTAssertEqual(active.outgoingShader(), .fade(time: 0.999))
    }

    func testSceneManagerStateCodableRoundTripMidTransition() throws {
        let state = SceneManagerState(
            activeSceneId: "a",
            transition: ActiveSceneTransition(
                outgoingSceneId: "a",
                incomingSceneId: "b",
                transition: .crossFade(duration: 1.5),
                elapsed: 0.4
            )
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(SceneManagerState.self, from: data)
        XCTAssertEqual(decoded, state)
        XCTAssertEqual(decoded.transition?.elapsed ?? 0, 0.4, accuracy: 1e-9)
    }
}
