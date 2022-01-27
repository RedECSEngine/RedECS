import Foundation
import RedECS

public enum KeyboardInput: UInt16, Codable, Equatable {
    case a = 0
    case s = 1
    case d = 2
    case q = 12
    case w = 13
    case e = 14
    
    case enter = 36
    case space = 49
    case esc = 53
    
    case upKey = 126
    case downKey = 125
    case rightKey = 124
    case leftKey = 123
}

public struct KeyboardInputComponent<Action: Equatable & Codable>: GameComponent {
    public struct Mapping: Equatable, Codable {
        public var keySet: Set<KeyboardInput>
        public var action: Action
    }
    
    public var entity: EntityId
    public var pressedKeys: [KeyboardInput: Bool]
    public var keyMap: [Mapping]
    
    public init(
        entity: EntityId,
        pressedKeys: [KeyboardInput: Bool] = [:],
        keyMap: [(Set<KeyboardInput>, Action)] = []
    ) {
        self.entity = entity
        self.pressedKeys = pressedKeys
        self.keyMap = keyMap.map(Mapping.init)
    }
    
    public func isKeyPressed(_ key: KeyboardInput) -> Bool {
       pressedKeys[key] == true
    }
    
    public func isAnyKeyPressed(in keySet: Set<KeyboardInput>) -> Bool {
        return keySet.contains(where: isKeyPressed)
    }
}
