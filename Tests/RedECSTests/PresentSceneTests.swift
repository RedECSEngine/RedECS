import XCTest
@testable import RedECS
import RedECSBasicComponents

final class PresentSceneTests: XCTestCase {
    private func makeStore() -> GameStore<AnyReducer<TestGlobalState, TestGlobalAction, TestGlobalEnvironment>> {
        GameStore(
            state: TestGlobalState(),
            environment: TestGlobalEnvironment(),
            reducer: TestGlobalReducer().eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.transform),
            ]
        )
    }

    func testSetHiddenTogglesTransformVisibility() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("a", []))
        store.sendSystemAction(.addComponent(TransformComponent(entity: "a"), into: \.transform))
        XCTAssertEqual(store.state.transform["a"]?.isHidden, false)

        store.sendSystemAction(.setHidden("a", true))
        XCTAssertEqual(store.state.transform["a"]?.isHidden, true)

        store.sendSystemAction(.setHidden("a", false))
        XCTAssertEqual(store.state.transform["a"]?.isHidden, false)
    }
}
