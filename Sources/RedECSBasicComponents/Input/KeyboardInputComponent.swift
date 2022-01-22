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

public struct KeyboardInputComponent: GameComponent {
    public var entity: EntityId
    public var pressedKeys: [KeyboardInput: Bool]
    
    public init(
        entity: EntityId,
        pressedKeys: [KeyboardInput: Bool] = [:]
    ) {
        self.entity = entity
        self.pressedKeys = pressedKeys
    }
    
    public func isKeyPressed(_ key: KeyboardInput) -> Bool {
       pressedKeys[key] == true
    }
    
    public func isAnyKeyPressed(in keys: Set<KeyboardInput>) -> Bool {
        return keys.contains(where: isKeyPressed)
    }
}
