import XCTest
import Geometry
@testable import RedECS

final class FollowPathOperationTests: XCTestCase {

    private let id: EntityId = "walker"

    /// `OperationType.run` now takes the game's root state, so these tests use the
    /// engine's own `OperationCapableGameState` rather than the bare context.
    private func makeState<A: Equatable & Codable>(startAt position: Point) -> OperationComponentContext<A> {
        OperationComponentContext(
            entities: .init(),
            operation: [:],
            transform: [id: TransformComponent(entity: id, position: position)],
            sprite: [:]
        )
    }

    private func makeContext(startAt position: Point) -> BasicOperationComponentContext {
        BasicOperationComponentContext(
            entities: .init(),
            transform: [id: TransformComponent(entity: id, position: position)],
            sprite: [:]
        )
    }

    func testStepsTowardTheFirstWaypointAtTravelSpeed() {
        var state = makeContext(startAt: .zero)
        var op = FollowPathOperation(path: [Point(x: 100, y: 0)], travelSpeed: 60)

        _ = op.run(id: id, state: &state, delta: 0.5)

        XCTAssertEqual(state.transform[id]?.position.x ?? 0, 30, accuracy: 0.0001)
        XCTAssertEqual(state.transform[id]?.position.y ?? 0, 0, accuracy: 0.0001)
        XCTAssertFalse(op.isComplete)
    }

    func testConsumesWaypointsAndCompletes() {
        var state = makeContext(startAt: .zero)
        var op = FollowPathOperation(path: [Point(x: 10, y: 0), Point(x: 10, y: 10)], travelSpeed: 60)

        for _ in 0..<60 where !op.isComplete {
            _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)
        }

        XCTAssertTrue(op.isComplete)
        XCTAssertEqual(state.transform[id]?.position, Point(x: 10, y: 10))
    }

    func testOvershootSnapsToTheWaypointInsteadOfOrbiting() {
        var state = makeContext(startAt: .zero)
        var op = FollowPathOperation(path: [Point(x: 20, y: 0)], travelSpeed: 600)

        for _ in 0..<10 where !op.isComplete {
            _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)
        }

        XCTAssertTrue(op.isComplete, "a step larger than the remaining distance must land, not orbit")
        XCTAssertEqual(state.transform[id]?.position, Point(x: 20, y: 0))
    }

    func testDiagonalTravelMovesAtUniformSpeed() {
        var state = makeContext(startAt: .zero)
        var op = FollowPathOperation(path: [Point(x: 30, y: 40)], travelSpeed: 50)

        _ = op.run(id: id, state: &state, delta: 0.5)

        let position = state.transform[id]?.position ?? .zero
        XCTAssertEqual(position.distanceFrom(.zero), 25, accuracy: 0.0001)
    }

    func testMissingTransformCompletesImmediately() {
        var state = makeContext(startAt: .zero)
        state.transform = [:]
        var op = FollowPathOperation(path: [Point(x: 100, y: 0)], travelSpeed: 60)

        _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)

        XCTAssertTrue(op.isComplete)
    }

    func testResetRewindsToTheFirstWaypoint() {
        var state = makeContext(startAt: .zero)
        var op = FollowPathOperation(path: [Point(x: 1, y: 0)], travelSpeed: 60)
        for _ in 0..<10 where !op.isComplete {
            _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)
        }
        XCTAssertTrue(op.isComplete)

        op.reset()

        XCTAssertFalse(op.isComplete)
        XCTAssertEqual(op.currentIndex, 0)
    }

    func testSequencedCallRunsAfterThePathCompletes() {
        var state: OperationComponentContext<String> = makeState(startAt: .zero)
        var op: OperationType<String> = OperationType
            .followPath([Point(x: 10, y: 0)], travelSpeed: 60)
            .call("arrived")

        var calls: [String] = []
        for _ in 0..<60 where !op.isComplete {
            let effect = op.run(id: id, state: &state, delta: 1.0 / 60.0, registration: .init())
            if case .game(let action) = effect { calls.append(action) }
        }

        XCTAssertEqual(calls, ["arrived"])
        XCTAssertTrue(op.isComplete)
    }

    func testSpeedOperationAcceleratesAPathFollow() {
        var state: OperationComponentContext<String> = makeState(startAt: .zero)
        var op: OperationType<String> = OperationType
            .followPath([Point(x: 100, y: 0)], travelSpeed: 60)
            .speed(2)

        _ = op.run(id: id, state: &state, delta: 0.5, registration: .init())

        XCTAssertEqual(state.transform[id]?.position.x ?? 0, 60, accuracy: 0.0001)
    }
}

final class SpeedOperationTests: XCTestCase {

    private let id: EntityId = "runner"

    func testScalesTheDeltaFedToTheWrappedOperation() {
        var state = OperationComponentContext<Int>(
            entities: .init(),
            operation: [:],
            transform: [id: TransformComponent(entity: id, position: .zero)],
            sprite: [:]
        )
        var op: OperationType<Int> = OperationType
            .move(.by(Point(x: 100, y: 0)), duration: 1)
            .speed(2)

        _ = op.run(id: id, state: &state, delta: 0.25, registration: .init())

        XCTAssertEqual(state.transform[id]?.position.x ?? 0, 50, accuracy: 0.0001)
        XCTAssertFalse(op.isComplete)

        _ = op.run(id: id, state: &state, delta: 0.25, registration: .init())
        XCTAssertEqual(state.transform[id]?.position.x ?? 0, 100, accuracy: 0.0001)
        XCTAssertTrue(op.isComplete)
    }

    func testHalvesDurationInReporting() {
        let op: OperationType<Int> = OperationType
            .move(.by(Point(x: 100, y: 0)), duration: 1)
            .speed(2)
        XCTAssertEqual(op.duration, 0.5)
    }
}
