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
        XCTAssertEqual(store.state.entities.tree.children?.map(\.id), ["a"])
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
        XCTAssertEqual(store.state.entities.tree.childCount, 0)
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
