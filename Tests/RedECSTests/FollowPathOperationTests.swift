import XCTest
import Geometry
@testable import RedECS

final class FollowPathOperationTests: XCTestCase {

    private let id: EntityId = "walker"

    private func makeContext(
        startAt position: Point,
        travelSpeed: Double = 60
    ) -> BasicOperationComponentContext {
        BasicOperationComponentContext(
            entities: .init(),
            transform: [id: TransformComponent(entity: id, position: position)],
            sprite: [:],
            movement: [id: MovementComponent(entity: id, velocity: .zero, travelSpeed: travelSpeed)]
        )
    }

    private func applyMovement(_ state: inout BasicOperationComponentContext, delta: Double) {
        guard let movement = state.movement[id] else { return }
        state.transform[id]?.position += movement.velocity * delta * movement.travelSpeed
        state.movement[id]?.velocity = .zero
    }

    func testWalksTowardTheFirstWaypointByVelocity() {
        var state = makeContext(startAt: .zero)
        var op = FollowPathOperation(path: [Point(x: 100, y: 0)])

        _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)

        XCTAssertEqual(state.movement[id]?.velocity, Point(x: 1, y: 0))
        XCTAssertFalse(op.isComplete)
    }

    func testSpeedScalesTheVelocity() {
        var state = makeContext(startAt: .zero)
        var op = FollowPathOperation(path: [Point(x: 100, y: 0)], speed: 3)

        _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)

        XCTAssertEqual(state.movement[id]?.velocity, Point(x: 3, y: 0))
    }

    func testConsumesWaypointsAndCompletes() {
        var state = makeContext(startAt: .zero)
        var op = FollowPathOperation(path: [Point(x: 10, y: 0), Point(x: 20, y: 0)])

        for _ in 0..<120 where !op.isComplete {
            _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)
            applyMovement(&state, delta: 1.0 / 60.0)
        }

        XCTAssertTrue(op.isComplete)
        XCTAssertEqual(state.transform[id]?.position, Point(x: 20, y: 0))
        XCTAssertEqual(state.movement[id]?.velocity, .zero)
    }

    func testFastTravelDoesNotOscillateAroundAWaypoint() {
        var state = makeContext(startAt: .zero, travelSpeed: 60)
        var op = FollowPathOperation(path: [Point(x: 20, y: 0)], speed: 4)

        for _ in 0..<30 where !op.isComplete {
            _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)
            applyMovement(&state, delta: 1.0 / 60.0)
        }

        XCTAssertTrue(op.isComplete, "a step larger than the proximity variance must still land, not orbit")
        XCTAssertEqual(state.transform[id]?.position, Point(x: 20, y: 0))
    }

    func testMissingMovementComponentCompletesImmediately() {
        var state = makeContext(startAt: .zero)
        state.movement = [:]
        var op = FollowPathOperation(path: [Point(x: 100, y: 0)])

        _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)

        XCTAssertTrue(op.isComplete)
    }

    func testResetRestoresTheFullPath() {
        var state = makeContext(startAt: .zero)
        var op = FollowPathOperation(path: [Point(x: 1, y: 0)])
        for _ in 0..<10 where !op.isComplete {
            _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)
            applyMovement(&state, delta: 1.0 / 60.0)
        }
        XCTAssertTrue(op.isComplete)

        op.reset()

        XCTAssertFalse(op.isComplete)
        XCTAssertEqual(op.remaining, op.path)
    }

    func testSequencedCallRunsAfterThePathCompletes() {
        var state = makeContext(startAt: .zero)
        var op: OperationType<String> = OperationType
            .followPath([Point(x: 10, y: 0)])
            .call("arrived")

        var calls: [String] = []
        for _ in 0..<60 where !op.isComplete {
            let effect = op.run(id: id, state: &state, delta: 1.0 / 60.0)
            if case .game(let action) = effect { calls.append(action) }
            applyMovement(&state, delta: 1.0 / 60.0)
        }

        XCTAssertEqual(calls, ["arrived"])
        XCTAssertTrue(op.isComplete)
    }
}

final class SpeedOperationTests: XCTestCase {

    private let id: EntityId = "runner"

    func testScalesTheDeltaFedToTheWrappedOperation() {
        var state = BasicOperationComponentContext(
            entities: .init(),
            transform: [id: TransformComponent(entity: id, position: .zero)],
            sprite: [:]
        )
        var op: OperationType<Int> = OperationType
            .move(.by(Point(x: 100, y: 0)), duration: 1)
            .speed(2)

        _ = op.run(id: id, state: &state, delta: 0.25)

        XCTAssertEqual(state.transform[id]?.position.x ?? 0, 50, accuracy: 0.0001)
        XCTAssertFalse(op.isComplete)

        _ = op.run(id: id, state: &state, delta: 0.25)
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

final class PendingCallActionsTests: XCTestCase {

    private let id: EntityId = "walker"

    func testUnrunSequenceReportsItsCallbacks() {
        let op: OperationType<String> = OperationType
            .followPath([.init(x: 10, y: 0)])
            .call("arrived")
        XCTAssertEqual(op.pendingCallActions, ["arrived"])
    }

    func testFiredCallbacksAreNotReported() {
        var state = BasicOperationComponentContext(
            entities: .init(),
            transform: [id: TransformComponent(entity: id, position: .zero)],
            sprite: [:],
            movement: [id: MovementComponent(entity: id, velocity: .zero, travelSpeed: 600)]
        )
        var op: OperationType<String> = OperationType
            .followPath([.init(x: 1, y: 0)])
            .call("arrived")
        for _ in 0..<10 where !op.isComplete {
            _ = op.run(id: id, state: &state, delta: 1.0 / 60.0)
        }
        XCTAssertTrue(op.isComplete)
        XCTAssertEqual(op.pendingCallActions, [])
    }

    func testLeafOperationsReportNothing() {
        let op: OperationType<String> = .move(.by(.init(x: 1, y: 0)), duration: 1)
        XCTAssertEqual(op.pendingCallActions, [])
    }
}
