import Foundation
import RedECS
import Geometry

public struct KeyboardInputReducerContext: GameState {
    public var entities: Set<EntityId> = []
    public var keyboardInput: [EntityId: KeyboardInputComponent] = [:]
    
    public init(
        entities: Set<EntityId> = [],
        keyboardInput: [EntityId: KeyboardInputComponent] = [:]
    ) {
        self.entities = entities
        self.keyboardInput = keyboardInput
    }
}

public enum KeyboardInputAction: Equatable {
    case keyDown(KeyboardInput)
    case keyUp(KeyboardInput)
}

public struct KeyboardInputReducer: Reducer {
    
    public init() { }
    
    public func reduce(
        state: inout KeyboardInputReducerContext,
        action: KeyboardInputAction,
        environment: Void
    ) -> GameEffect<KeyboardInputReducerContext, KeyboardInputAction> {
        state.keyboardInput.forEach { (keyboardId, _) in
            switch action {
            case .keyDown(let keyboardInput):
                state.keyboardInput[keyboardId]?.pressedKeys[keyboardInput] = true
            case .keyUp(let keyboardInput):
                state.keyboardInput[keyboardId]?.pressedKeys.removeValue(forKey: keyboardInput)
            }
        }
        return .none
    }
    
    public func reduce(
        state: inout KeyboardInputReducerContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<KeyboardInputReducerContext, KeyboardInputAction> {
        .none
    }
}
