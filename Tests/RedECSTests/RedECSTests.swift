import XCTest
@testable import RedECS

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
            + TestMovementReducer()
            .pullback(
                toLocalState: \TestGlobalState.movementState,
                toLocalAction: { $0 },
                toGlobalAction: { $0 },
                toLocalEnvironment: { $0 }
            )
    )
    .eraseToAnyReducer()

    func testGlobalAndLocalReducerBothManipulateState() {
        // Given
        let store = GameStore(
            state: TestGlobalState(count: 0),
            environment: TestGlobalEnvironment(),
            reducer: reducer,
            registeredComponentTypes: []
        )
        
        // When
        store.sendAction(.tick)
        
        // Expect
        XCTAssertEqual(store.state.count, 2)
    }
    
    func testComponentReduction() {
        // Given
        let store = GameStore(
            state: TestGlobalState(count: 0),
            environment: TestGlobalEnvironment(),
            reducer: reducer,
            registeredComponentTypes: [
                .init(keyPath: \.positions),
                .init(keyPath: \.movement)
            ]
        )
        
        let newEntity: EntityId = UUID().uuidString
        store.sendSystemAction(.addEntity(newEntity))
        store.sendSystemAction(.addComponent(TestTransformComponent(entity: newEntity, position: .zero), into: \.positions))
        store.sendSystemAction(.addComponent(TestMovementComponent(entity: newEntity, velocity: .init(x: 1, y: 0)), into: \.movement))

        // When
        store.sendAction(.tick)
        
        // Expect
        XCTAssertEqual(store.state.transforms[newEntity]?.x, 1)
        
        // When
        store.sendAction(.updateVelocity(entity: newEntity, velocity: .zero))
        store.sendAction(.tick)
        
        // Expect
        XCTAssertEqual(store.state.transforms[newEntity]?.x, 1)
    }
    
    func testSystemActionThroughReducer() throws {
        // Given
        let env = TestGlobalEnvironment()
        let store = GameStore(
            state: TestGlobalState(count: 0),
            environment: env,
            reducer: reducer,
            registeredComponentTypes: [
                .init(keyPath: \.positions),
                .init(keyPath: \.movement)
            ]
        )
        
        let newEntity: EntityId = UUID().uuidString
        store.sendSystemAction(.addEntity(newEntity))
        store.sendSystemAction(.addComponent(TestTransformComponent(entity: newEntity, position: .zero), into: \.positions))
        store.sendSystemAction(.addComponent(TestMovementComponent(entity: newEntity, velocity: .init(x: 1, y: 0)), into: \.movement))
        
        // Expect
        XCTAssertNotEqual(store.state.entities, [])
        XCTAssertNotEqual(store.state.transforms[newEntity], nil)
        XCTAssertNotEqual(store.state.movement[newEntity], nil)
        
        // When
        store.sendAction(.removeEntity(entity: newEntity))
        
        // Expect
        XCTAssertEqual(store.state.entities, [])
        XCTAssertEqual(store.state.transforms[newEntity], nil)
        XCTAssertEqual(store.state.movement[newEntity], nil)
    }
    
    func testStateSavingAndRestoration() throws {
        // Given
        let store = GameStore(
            state: TestGlobalState(count: 0),
            environment: TestGlobalEnvironment(),
            reducer: reducer,
            registeredComponentTypes: [
                .init(keyPath: \.positions),
                .init(keyPath: \.movement)
            ]
        )
        
        let newEntity: EntityId = UUID().uuidString
        store.sendSystemAction(.addEntity(newEntity))
        store.sendSystemAction(.addComponent(TestTransformComponent(entity: newEntity, position: .zero), into: \.positions))
        store.sendSystemAction(.addComponent(TestMovementComponent(entity: newEntity, velocity: .init(x: 1, y: 0)), into: \.movement))
        
        // When
        store.sendAction(.tick)
        
        // Expect
        XCTAssertEqual(store.state.transforms[newEntity]?.x, 1)
        
        // When
        let data = try store.saveState()
        let newStore = try GameStore(
            data: data,
            environment: TestGlobalEnvironment(),
            reducer: TestGlobalReducer()
                + TestMovementReducer()
                .pullback(
                    toLocalState: \TestGlobalState.movementState,
                    toLocalAction: { $0 },
                    toGlobalAction: { $0 },
                    toLocalEnvironment: { $0 }
                ),
            registeredComponentTypes: [
                .init(keyPath: \.positions),
                .init(keyPath: \.movement)
            ]
        )
        
        // Expect
        XCTAssertEqual(newStore.state.entities, [newEntity])
        XCTAssertEqual(newStore.state.transforms[newEntity]?.x, 1)
    }
}
