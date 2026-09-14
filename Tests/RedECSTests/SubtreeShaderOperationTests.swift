@testable import RedECS
import Geometry
import XCTest

final class SubtreeShaderOperationTests: XCTestCase {
    private func makeContext() -> BasicOperationComponentContext {
        var entities = EntityRepository()
        entities.addEntity(GameEntity(id: "scene", tags: []))
        entities.addEntity(GameEntity(id: "hero", tags: []), under: "scene")
        entities.addEntity(GameEntity(id: "sword", tags: []), under: "hero")
        entities.addEntity(GameEntity(id: "outsider", tags: []))
        var sprites: [EntityId: SpriteComponent] = [:]
        for id in ["scene", "hero", "sword", "outsider"] {
            sprites[id] = SpriteComponent(entity: id)
        }
        return BasicOperationComponentContext(
            entities: entities,
            transform: [:],
            sprite: sprites
        )
    }

    func testWritesAdvancingShaderAcrossSubtreeOnly() {
        var state = makeContext()
        var op = SubtreeShaderOperation(effect: .fade, duration: 1)

        _ = op.run(id: "scene", state: &state, delta: 0.25)
        for id in ["scene", "hero", "sword"] {
            XCTAssertEqual(state.sprite[id]?.shader, .fade(time: 0.25))
        }
        XCTAssertNil(state.sprite["outsider"]?.shader)

        _ = op.run(id: "scene", state: &state, delta: 0.25)
        XCTAssertEqual(state.sprite["sword"]?.shader, .fade(time: 0.5))
        XCTAssertFalse(op.isComplete)
    }

    func testReversedRunsTimeBackwards() {
        var state = makeContext()
        var op = SubtreeShaderOperation(effect: .turnOff, duration: 1, reversed: true)

        _ = op.run(id: "scene", state: &state, delta: 0.25)
        XCTAssertEqual(state.sprite["hero"]?.shader, .turnOff(time: 0.75))

        _ = op.run(id: "scene", state: &state, delta: 0.5)
        XCTAssertEqual(state.sprite["hero"]?.shader, .turnOff(time: 0.25))
    }

    func testCompletionClearsSubtreeShaders() {
        var state = makeContext()
        state.sprite["outsider"]?.shader = .tint(.red)
        var op = SubtreeShaderOperation(effect: .fade, duration: 0.5)

        _ = op.run(id: "scene", state: &state, delta: 0.3)
        _ = op.run(id: "scene", state: &state, delta: 0.3)

        XCTAssertTrue(op.isComplete)
        for id in ["scene", "hero", "sword"] {
            XCTAssertNil(state.sprite[id]?.shader)
        }
        XCTAssertEqual(state.sprite["outsider"]?.shader, .tint(.red))
    }

    func testMidTransitionSpawnsAreIncluded() {
        var state = makeContext()
        var op = SubtreeShaderOperation(effect: .fade, duration: 1)
        _ = op.run(id: "scene", state: &state, delta: 0.25)

        state.entities.addEntity(GameEntity(id: "latecomer", tags: []), under: "scene")
        state.sprite["latecomer"] = SpriteComponent(entity: "latecomer")
        _ = op.run(id: "scene", state: &state, delta: 0.25)

        XCTAssertEqual(state.sprite["latecomer"]?.shader, .fade(time: 0.5))
    }

    func testShaderTimeClampsBelowOne() {
        var state = makeContext()
        var op = SubtreeShaderOperation(effect: .turnOff, duration: 1, reversed: true)
        _ = op.run(id: "scene", state: &state, delta: 0.0001)
        guard case .turnOff(let time)? = state.sprite["hero"]?.shader else {
            return XCTFail("expected turnOff")
        }
        XCTAssertLessThanOrEqual(time, 0.999)
    }

    func testOperationComponentCodableRoundTripMidFlight() throws {
        var state = makeContext()
        var component = OperationComponent<String>(entity: "scene")
        component.newOperation(name: "sceneTransition", .subtreeShader(.fade, duration: 1))

        if case .subtreeShader(var op)? = component.operations["sceneTransition"] {
            _ = op.run(id: "scene", state: &state, delta: 0.4)
            component.operations["sceneTransition"] = .subtreeShader(op)
        } else {
            return XCTFail("expected subtreeShader")
        }

        let data = try JSONEncoder().encode(component)
        let decoded = try JSONDecoder().decode(OperationComponent<String>.self, from: data)
        XCTAssertEqual(decoded, component)

        if case .subtreeShader(var op)? = decoded.operations["sceneTransition"] {
            _ = op.run(id: "scene", state: &state, delta: 0.2)
            guard case .fade(let time)? = state.sprite["hero"]?.shader else {
                return XCTFail("expected fade")
            }
            XCTAssertEqual(time, 0.6, accuracy: 1e-9)
        } else {
            return XCTFail("expected subtreeShader after decode")
        }
    }
}
