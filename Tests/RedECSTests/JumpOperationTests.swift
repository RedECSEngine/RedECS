import XCTest
import Geometry
@testable import RedECS
import RedECSBasicComponents

final class JumpOperationTests: XCTestCase {

    private func makeContext(startAt position: Point) -> (EntityId, OperationTestContext) {
        let id: EntityId = "jumper"
        let context = OperationTestContext(
            entities: .init(),
            transform: [id: TransformComponent(entity: id, position: position)],
            sprite: [:]
        )
        return (id, context)
    }

    /// Feed the operation four 0.25s steps over a 1s duration and collect the
    /// position after each step. The first step resolves `delta` (currentTime == 0).
    private func run(
        _ op: inout JumpOperation,
        id: EntityId,
        state: inout OperationTestContext
    ) -> [Point] {
        var positions: [Point] = []
        for _ in 0..<4 {
            _ = op.run(id: id, state: &state, delta: 0.25)
            positions.append(state.transform[id]?.position ?? .zero)
        }
        return positions
    }

    func testJumpByTracesParabolaAndLandsAtOffset() {
        var (id, state) = (makeContext(startAt: .zero))
        var op = JumpOperation(strategy: .by(Point(x: 100, y: 0)), height: 50, jumps: 1, duration: 1)

        let positions = run(&op, id: id, state: &state)

        // t = 0.25: x = 25, y = 50*4*0.25*0.75 = 37.5
        XCTAssertEqual(positions[0].x, 25, accuracy: 0.0001)
        XCTAssertEqual(positions[0].y, 37.5, accuracy: 0.0001)
        // t = 0.50: peak of a single jump — x = 50, y = 50
        XCTAssertEqual(positions[1].x, 50, accuracy: 0.0001)
        XCTAssertEqual(positions[1].y, 50, accuracy: 0.0001)
        // t = 1.00: arc returns to 0, landing exactly on the offset
        XCTAssertEqual(positions[3].x, 100, accuracy: 0.0001)
        XCTAssertEqual(positions[3].y, 0, accuracy: 0.0001)
        XCTAssertTrue(op.isComplete)
    }

    func testJumpToLandsAtAbsolutePositionRegardlessOfStart() {
        var (id, state) = (makeContext(startAt: Point(x: 10, y: 10)))
        var op = JumpOperation(strategy: .to(Point(x: 110, y: 10)), height: 40, jumps: 1, duration: 1)

        let positions = run(&op, id: id, state: &state)

        // Resolved delta is (100, 0); halfway peaks 40 above the linear path.
        XCTAssertEqual(positions[1].x, 60, accuracy: 0.0001)
        XCTAssertEqual(positions[1].y, 50, accuracy: 0.0001) // 10 + 40 peak
        // Lands exactly on the target.
        XCTAssertEqual(positions[3].x, 110, accuracy: 0.0001)
        XCTAssertEqual(positions[3].y, 10, accuracy: 0.0001)
    }

    func testMultipleJumpsLandExactlyAtOffset() {
        var (id, state) = (makeContext(startAt: .zero))
        var op = JumpOperation(strategy: .by(Point(x: 80, y: 0)), height: 30, jumps: 2, duration: 1)

        let positions = run(&op, id: id, state: &state)

        // With jumps = 2 the arc peaks at t = 0.25 and t = 0.75 and is 0 at t = 0.5.
        XCTAssertEqual(positions[0].y, 30, accuracy: 0.0001) // peak
        XCTAssertEqual(positions[1].y, 0, accuracy: 0.0001)  // touchdown between jumps
        XCTAssertEqual(positions[2].y, 30, accuracy: 0.0001) // peak
        // Still lands exactly on the offset.
        XCTAssertEqual(positions[3].x, 80, accuracy: 0.0001)
        XCTAssertEqual(positions[3].y, 0, accuracy: 0.0001)
    }

    func testResetReplaysFromCurrentPosition() {
        var (id, state) = (makeContext(startAt: .zero))
        var op = JumpOperation(strategy: .by(Point(x: 100, y: 0)), height: 50, jumps: 1, duration: 1)

        _ = run(&op, id: id, state: &state)
        XCTAssertTrue(op.isComplete)

        op.reset()
        XCTAssertFalse(op.isComplete)
        XCTAssertEqual(op.currentTime, 0, accuracy: 0.0001)

        // Replays the same offset from wherever the entity now sits (x = 100).
        let positions = run(&op, id: id, state: &state)
        XCTAssertEqual(positions[3].x, 200, accuracy: 0.0001)
        XCTAssertEqual(positions[3].y, 0, accuracy: 0.0001)
    }
}
