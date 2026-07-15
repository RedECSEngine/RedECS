import RedECS

// Raw values are macOS (Carbon `kVK_*`) virtual key codes.
public enum KeyboardInput: UInt16, Codable, Equatable {
    case a = 0
    case b = 11
    case c = 8
    case d = 2
    case e = 14
    case f = 3
    case g = 5
    case h = 4
    case i = 34
    case j = 38
    case k = 40
    case l = 37
    case m = 46
    case n = 45
    case o = 31
    case p = 35
    case q = 12
    case r = 15
    case s = 1
    case t = 17
    case u = 32
    case v = 9
    case w = 13
    case x = 7
    case y = 16
    case z = 6

    case zero = 29
    case one = 18
    case two = 19
    case three = 20
    case four = 21
    case five = 23
    case six = 22
    case seven = 26
    case eight = 28
    case nine = 25

    case minus = 27
    case equal = 24
    case leftBracket = 33
    case rightBracket = 30
    case backslash = 42
    case semicolon = 41
    case quote = 39
    case comma = 43
    case period = 47
    case slash = 44

    case tab = 48
    case enter = 36
    case space = 49
    case esc = 53

    // macOS delivers these via flagsChanged, not keyDown/keyUp.
    case shift = 56
    case control = 59
    case alt = 58

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
