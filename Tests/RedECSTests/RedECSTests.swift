import Foundation
import XCTest
@testable import RedECS
import RedECSBasicComponents
import RedECSAppleSupport

class RedECSTests: XCTestCase {
    
    let reducer = (
        TestGlobalReducer()
            + TestLocalReducer()
            .pullback(
                toLocalState: \TestGlobalState.containedState,
                toLocalAction: { $0 },
                toGlobalAction: { $0 },
                toLocalEnvironment: { $0 }
            )
            + MovementReducer()
            .pullback(
                toLocalState: \TestGlobalState.movementContext
            )
    )
    .eraseToAnyReducer()

    func testGlobalAndLocalReducerBothManipulateState() {
        // Given
        let store = GameStore(
            state: TestGlobalState(),
            environment: TestGlobalEnvironment(),
            reducer: reducer,
            registeredComponentTypes: []
        )
        
        // When
        store.sendAction(.incrementCount)
        
        // Expect
        XCTAssertEqual(store.state.count, 2)
    }
    
    func testComponentReduction() {
        // Given
        let store = GameStore(
            state: TestGlobalState(),
            environment: TestGlobalEnvironment(),
            reducer: reducer,
            registeredComponentTypes: [
                .init(keyPath: \.transform),
                .init(keyPath: \.movement)
            ]
        )
        
        let newEntity: EntityId = newEntityId()
        store.sendSystemAction(.addEntity(newEntity, []))
        store.sendSystemAction(.addComponent(TransformComponent(entity: newEntity, position: .zero), into: \.transform))
        store.sendSystemAction(.addComponent(MovementComponent(entity: newEntity, velocity: .init(x: 1, y: 0), travelSpeed: 1), into: \.movement))

        // When
        store.sendDelta(1)
        
        // Expect
        XCTAssertEqual(store.state.transform[newEntity]?.position.x, 1)
        
        // When
        store.sendAction(.updateVelocity(entity: newEntity, velocity: .zero))
        
        // Expect
        XCTAssertEqual(store.state.transform[newEntity]?.position.x, 1)
    }
    
    func testSystemActionThroughReducer() throws {
        // Given
        let env = TestGlobalEnvironment()
        let store = GameStore(
            state: TestGlobalState(),
            environment: env,
            reducer: reducer,
            registeredComponentTypes: [
                .init(keyPath: \.transform),
                .init(keyPath: \.movement)
            ]
        )
        
        let newEntity: EntityId = UUID().uuidString
        store.sendSystemAction(.addEntity(newEntity, []))
        store.sendSystemAction(.addComponent(TransformComponent(entity: newEntity, position: .zero), into: \.transform))
        store.sendSystemAction(.addComponent(MovementComponent(entity: newEntity, velocity: .init(x: 1, y: 0), travelSpeed: 1), into: \.movement))
        
        // Expect
        XCTAssertNotEqual(store.state.entities.entities.count, 0)
        XCTAssertNotEqual(store.state.transform[newEntity], nil)
        XCTAssertNotEqual(store.state.movement[newEntity], nil)
        
        // When
        store.sendAction(.removeEntity(entity: newEntity))
        
        // Expect
        XCTAssertEqual(store.state.entities.entities.count, 0)
        XCTAssertEqual(store.state.transform[newEntity], nil)
        XCTAssertEqual(store.state.movement[newEntity], nil)
    }
    
    func testStateSavingAndRestoration() throws {
        // Given
        let store = GameStore(
            state: TestGlobalState(),
            environment: TestGlobalEnvironment(),
            reducer: reducer,
            registeredComponentTypes: [
                .init(keyPath: \.transform),
                .init(keyPath: \.movement)
            ]
        )
        
        let newEntity: EntityId = UUID().uuidString
        store.sendSystemAction(.addEntity(newEntity, []))
        store.sendSystemAction(
            .addComponent(TransformComponent(entity: newEntity,
            position: .zero),
            into: \.transform)
        )
        store.sendSystemAction(
            .addComponent(MovementComponent(entity: newEntity,
            velocity: .init(x: 1,
            y: 0),
            travelSpeed: 1),
            into: \.movement)
        )
        
        // When
        store.sendDelta(1)
        
        // Expect
        XCTAssertEqual(store.state.transform[newEntity]?.position.x, 1)
        
        // When
        let data = try store.saveState()
        let newStore = try GameStore(
            data: data,
            environment: TestGlobalEnvironment(),
            reducer: TestGlobalReducer()
                + MovementReducer()
                .pullback(
                    toLocalState: \TestGlobalState.movementContext
                ),
            registeredComponentTypes: [
                .init(keyPath: \.transform),
                .init(keyPath: \.movement)
            ]
        )
        
        // Expect
        XCTAssertEqual(newStore.state.entities.entities.keys.first, newEntity)
        XCTAssertEqual(newStore.state.transform[newEntity]?.position.x, 1)
    }
}
