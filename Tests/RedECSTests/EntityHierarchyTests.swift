import XCTest
@testable import RedECS
import RedECSBasicComponents

final class EntityHierarchyTests: XCTestCase {

    func makeStore() -> GameStore<AnyReducer<TestGlobalState, TestGlobalAction, TestGlobalEnvironment>> {
        GameStore(
            state: TestGlobalState(),
            environment: TestGlobalEnvironment(),
            reducer: TestGlobalReducer().eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.transform),
            ]
        )
    }

    func testEntitiesDefaultToRootParent() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("a", []))

        XCTAssertEqual(store.state.entities["a"]?.parentId, EntityRepository.Constants.rootTreeId)
        XCTAssertEqual(store.state.entities.hierarchy.roots, ["a"])
    }

    func testAddAndRemoveTagKeepsReverseIndexInSync() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("a", ["initial"]))

        // Adding a tag updates both the entity and the reverse index.
        store.sendSystemAction(.addTag("a", "player"))
        XCTAssertEqual(store.state.entities["a"]?.tags, ["initial", "player"])
        XCTAssertEqual(store.state.entities.tags["player"], ["a"])

        // Removing it clears both sides.
        store.sendSystemAction(.removeTag("a", "player"))
        XCTAssertEqual(store.state.entities["a"]?.tags, ["initial"])
        XCTAssertFalse(store.state.entities.tags["player"]?.contains("a") ?? false)
    }

    func testMovingATagBetweenEntities() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("hero", ["player"]))
        store.sendSystemAction(.addEntity("companion", []))

        // Hand the "player" marker from one entity to another.
        store.sendSystemAction(.removeTag("hero", "player"))
        store.sendSystemAction(.addTag("companion", "player"))

        XCTAssertEqual(store.state.entities.tags["player"], ["companion"])
        XCTAssertFalse(store.state.entities["hero"]?.tags.contains("player") ?? true)
        XCTAssertTrue(store.state.entities["companion"]?.tags.contains("player") ?? false)
    }

    func testRemovingAnEntityDropsItsTagsFromTheIndex() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("a", ["player"]))
        store.sendSystemAction(.addEntity("b", ["player"]))
        XCTAssertEqual(store.state.entities.tags["player"], ["a", "b"])

        store.sendSystemAction(.removeEntity("a"))
        XCTAssertEqual(store.state.entities.tags["player"], ["b"])
    }

    func testSetParentMovesEntityInTree() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("parent", []))
        store.sendSystemAction(.addEntity("child", []))
        store.sendSystemAction(.setParent("child", "parent"))

        XCTAssertEqual(store.state.entities["child"]?.parentId, "parent")
        XCTAssertEqual(store.state.entities.descendants(of: "parent"), ["child"])

        // and back to the root
        store.sendSystemAction(.setParent("child", nil))
        XCTAssertEqual(store.state.entities["child"]?.parentId, EntityRepository.Constants.rootTreeId)
        XCTAssertEqual(store.state.entities.descendants(of: "parent"), [])
    }

    func testAddEntityWithParentAtSpawn() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("parent", []))
        store.perform { state, _ in
            .system(.addEntity("child", []))
        }
        store.sendSystemAction(.setParent("child", "parent"))

        XCTAssertEqual(store.state.entities.descendants(of: "parent"), ["child"])
    }

    func testDescendantsAreDepthFirst() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("a", []))
        store.sendSystemAction(.addEntity("b", []))
        store.sendSystemAction(.addEntity("c", []))
        store.sendSystemAction(.setParent("b", "a"))
        store.sendSystemAction(.setParent("c", "b"))

        XCTAssertEqual(store.state.entities.descendants(of: "a"), ["b", "c"])
    }

    func testRemovingParentRemovesSubtree() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("parent", []))
        store.sendSystemAction(.addEntity("child", []))
        store.sendSystemAction(.addEntity("grandchild", []))
        store.sendSystemAction(.setParent("child", "parent"))
        store.sendSystemAction(.setParent("grandchild", "child"))
        store.sendSystemAction(.addComponent(TransformComponent(entity: "grandchild"), into: \.transform))

        store.sendSystemAction(.removeEntity("parent"))

        XCTAssertNil(store.state.entities["parent"])
        XCTAssertNil(store.state.entities["child"])
        XCTAssertNil(store.state.entities["grandchild"])
        XCTAssertNil(store.state.transform["grandchild"], "components of removed descendants should be destroyed")
        XCTAssertTrue(store.state.entities.hierarchy.roots.isEmpty)
    }

    func testSetParentKeepsMovedSubtree() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("newParent", []))
        store.sendSystemAction(.addEntity("mover", []))
        store.sendSystemAction(.addEntity("child", []))
        store.sendSystemAction(.addEntity("grandchild", []))
        store.sendSystemAction(.setParent("child", "mover"))
        store.sendSystemAction(.setParent("grandchild", "child"))

        store.sendSystemAction(.setParent("mover", "newParent"))

        XCTAssertEqual(store.state.entities["mover"]?.parentId, "newParent")
        XCTAssertEqual(store.state.entities.descendants(of: "newParent"), ["mover", "child", "grandchild"])
        XCTAssertEqual(store.state.entities.descendants(of: "mover"), ["child", "grandchild"])
    }

    func testSetParentToRootKeepsMovedSubtree() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("container", []))
        store.sendSystemAction(.addEntity("mover", []))
        store.sendSystemAction(.addEntity("child", []))
        store.sendSystemAction(.setParent("mover", "container"))
        store.sendSystemAction(.setParent("child", "mover"))

        store.sendSystemAction(.setParent("mover", nil))

        XCTAssertEqual(store.state.entities["mover"]?.parentId, EntityRepository.Constants.rootTreeId)
        XCTAssertEqual(store.state.entities.descendants(of: "mover"), ["child"])
        XCTAssertEqual(store.state.entities.descendants(of: "container"), [])
        XCTAssertEqual(store.state.entities.hierarchy.roots, ["container", "mover"])
    }

    func testRemoveEntityCascadesThroughMovedSubtree() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("newParent", []))
        store.sendSystemAction(.addEntity("mover", []))
        store.sendSystemAction(.addEntity("child", []))
        store.sendSystemAction(.setParent("child", "mover"))
        store.sendSystemAction(.addComponent(TransformComponent(entity: "child"), into: \.transform))

        store.sendSystemAction(.setParent("mover", "newParent"))
        store.sendSystemAction(.removeEntity("newParent"))

        XCTAssertNil(store.state.entities["newParent"])
        XCTAssertNil(store.state.entities["mover"])
        XCTAssertNil(store.state.entities["child"])
        XCTAssertNil(store.state.transform["child"])
        XCTAssertTrue(store.state.entities.hierarchy.roots.isEmpty)
    }

    func testStateSurvivesCodingRoundTripWithHierarchy() throws {
        let store = makeStore()
        store.sendSystemAction(.addEntity("parent", []))
        store.sendSystemAction(.addEntity("child", []))
        store.sendSystemAction(.setParent("child", "parent"))

        let data = try JSONEncoder().encode(store.state)
        let restored = try JSONDecoder().decode(TestGlobalState.self, from: data)

        XCTAssertEqual(restored.entities["child"]?.parentId, "parent")
        XCTAssertEqual(restored.entities.descendants(of: "parent"), ["child"])
    }
}
