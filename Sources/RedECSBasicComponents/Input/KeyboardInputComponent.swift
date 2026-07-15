import RedECS

public enum KeyboardInput: UInt16, Codable, Equatable {
    case a = 0
    case s = 1
    case d = 2
    case q = 12
    case w = 13
    case e = 14
    case r = 15

    case enter = 36
    case space = 49
    case esc = 53
    
    case upKey = 126
    case downKey = 125
    case rightKey = 124
    case leftKey = 123
}

public enum KeyboardTrigger: Equatable, Codable {
    case whileHeld
    case onPress
}

public struct KeyboardInputComponent<Action: Equatable & Codable>: GameComponent {
    public struct Mapping: Equatable, Codable {
        public var keySet: Set<KeyboardInput>
        public var action: Action
        public var trigger: KeyboardTrigger
        public init(keySet: Set<KeyboardInput>, action: Action, trigger: KeyboardTrigger = .whileHeld) {
            self.keySet = keySet
            self.action = action
            self.trigger = trigger
        }
    }

    public var entity: EntityId
    public var pressedKeys: [KeyboardInput: Bool]
    public var previousPressedKeys: [KeyboardInput: Bool]
    public var keyMap: [Mapping]

    public init(entity: EntityId) {
        self = .init(entity: entity, pressedKeys: [:], keyMap: [])
    }

    public init(
        entity: EntityId,
        pressedKeys: [KeyboardInput: Bool] = [:],
        keyMap: [Mapping] = []
    ) {
        self.entity = entity
        self.pressedKeys = pressedKeys
        self.previousPressedKeys = [:]
        self.keyMap = keyMap
    }

    public func isKeyPressed(_ key: KeyboardInput) -> Bool {
       pressedKeys[key] == true
    }

    public func isAnyKeyPressed(in keySet: Set<KeyboardInput>) -> Bool {
        return keySet.contains(where: isKeyPressed)
    }

    func wasAnyKeyPressed(in keySet: Set<KeyboardInput>) -> Bool {
        return keySet.contains { previousPressedKeys[$0] == true }
    }
}
