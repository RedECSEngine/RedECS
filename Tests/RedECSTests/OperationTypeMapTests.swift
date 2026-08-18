@testable import RedECS
import Geometry
import XCTest

private enum MapLocalAction: Equatable, Codable {
    case done(String)
}

private enum MapUmbrellaAction: Equatable, Codable {
    case finished(String)

    static func fromLocal(_ action: MapLocalAction) -> MapUmbrellaAction {
        switch action {
        case .done(let id): return .finished(id)
        }
    }
}

final class OperationTypeMapTests: XCTestCase {
    func testNestedChainMapsToExpectedTree() {
        let local: OperationType<MapLocalAction> = .sequence([
            .move(.by(.init(x: 10, y: 0)), duration: 1),
            .group([
                .wait(duration: 0.5),
                .call(.done("a"))
            ]),
            .call(.done("b")),
            .removeEntity()
        ])

        let expected: OperationType<MapUmbrellaAction> = .sequence([
            .move(.by(.init(x: 10, y: 0)), duration: 1),
            .group([
                .wait(duration: 0.5),
                .call(.finished("a"))
            ]),
            .call(.finished("b")),
            .removeEntity()
        ])

        XCTAssertEqual(local.map(MapUmbrellaAction.fromLocal), expected)
    }

    func testRepeatAndTimingStrategiesRetype() {
        let local: OperationType<MapLocalAction> = .repeat(
            RepeatOperation(
                strategy: .times(3),
                operation: .timing(TimingOperation(strategy: .easeInOut, operation: .wait(duration: 1)))
            )
        )

        let mapped = local.map(MapUmbrellaAction.fromLocal)

        guard case .repeat(let repeatOp) = mapped else {
            return XCTFail("expected repeat, got \(mapped)")
        }
        XCTAssertEqual(repeatOp.strategy, .times(3))
        guard case .timing(let timingOp) = repeatOp.operation else {
            return XCTFail("expected timing, got \(repeatOp.operation)")
        }
        XCTAssertEqual(timingOp.strategy, .easeInOut)
        XCTAssertEqual(timingOp.operation, .wait(duration: 1))
    }

    func testMapPreservesProgressOfPartiallyRunChain() {
        var local: OperationType<MapLocalAction> = .sequence([
            .wait(duration: 0.1),
            .call(.done("x"))
        ])
        var context = OperationComponentContext<MapLocalAction>(
            entities: .init(), operation: [:], transform: [:], sprite: [:]
        )
        _ = local.run(id: "e1", state: &context, delta: 0.2, registration: .init())

        let mapped = local.map(MapUmbrellaAction.fromLocal)

        guard case .sequence(let mappedSequence) = mapped else {
            return XCTFail("expected sequence, got \(mapped)")
        }
        guard case .sequence(let localSequence) = local else {
            return XCTFail("expected sequence, got \(local)")
        }
        XCTAssertEqual(mappedSequence.currentOperationIndex, 1)
        XCTAssertEqual(mappedSequence.currentOperationIndex, localSequence.currentOperationIndex)
        XCTAssertEqual(mappedSequence.currentTime, localSequence.currentTime)
        guard case .wait(let mappedWait) = mappedSequence.operations[0],
              case .wait(let localWait) = localSequence.operations[0] else {
            return XCTFail("expected wait as first op")
        }
        XCTAssertEqual(mappedWait.currentTime, localWait.currentTime)
        XCTAssertTrue(mappedWait.isComplete)
    }

    func testCallProgressSurvivesMapping() {
        var callOp = CallOperation<MapLocalAction>(action: .done("x"))
        var context = BasicOperationComponentContext(entities: .init(), transform: [:], sprite: [:])
        _ = callOp.run(id: "e1", state: &context, delta: 0.1)
        XCTAssertTrue(callOp.isComplete)

        let mapped = callOp.map(MapUmbrellaAction.fromLocal)
        XCTAssertTrue(mapped.isComplete)
        XCTAssertEqual(mapped.action, .finished("x"))
    }
}
