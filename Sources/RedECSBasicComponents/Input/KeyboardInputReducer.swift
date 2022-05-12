import RedECS
import Geometry

public struct KeyboardInputReducerContext<Action: Equatable & Codable>: GameState {
    public var entities: EntityRepository = .init()
    public var keyboardInput: [EntityId: KeyboardInputComponent<Action>] = [:]
    
    public init(
        entities: EntityRepository = .init(),
        keyboardInput: [EntityId: KeyboardInputComponent<Action>] = [:]
    ) {
        self.entities = entities
        self.keyboardInput = keyboardInput
    }
}

public enum KeyboardInputAction: Equatable & Codable {
    case keyDown(KeyboardInput)
    case keyUp(KeyboardInput)
}

public struct KeyboardKeyMapReducer<Action: Equatable & Codable>: Reducer {
    public init() { }
    
    public func reduce(state: inout KeyboardInputReducerContext<Action>, action: Action, environment: ()) -> GameEffect<KeyboardInputReducerContext<Action>, Action> {
        .none
    }
    
    public func reduce(
        state: inout KeyboardInputReducerContext<Action>,
        delta: Double,
        environment: Void
    ) -> GameEffect<KeyboardInputReducerContext<Action>, Action> {
        var effects: [GameEffect<KeyboardInputReducerContext<Action>, Action>] = []
        for keyboard in state.keyboardInput.values {
            for mapping in keyboard.keyMap {
                if keyboard.isAnyKeyPressed(in: mapping.keySet) {
                    effects.append(.game(mapping.action))
                }
            }
        }
        return .many(effects)
    }
}

public struct KeyboardInputReducer<Action: Equatable & Codable>: Reducer {
    
    public init() { }
    
    public func reduce(state: inout KeyboardInputReducerContext<Action>, delta: Double, environment: ()) -> GameEffect<KeyboardInputReducerContext<Action>, KeyboardInputAction> {
        .none
    }
    
    public func reduce(
        state: inout KeyboardInputReducerContext<Action>,
        action: KeyboardInputAction,
        environment: Void
    ) -> GameEffect<KeyboardInputReducerContext<Action>, KeyboardInputAction> {
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
}
