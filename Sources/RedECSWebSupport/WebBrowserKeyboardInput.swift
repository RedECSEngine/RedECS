import RedECSBasicComponents

// Raw values are web `KeyboardEvent.code` strings.
public enum WebBrowserKeyboardInput: String, Codable {
    case a = "KeyA"
    case b = "KeyB"
    case c = "KeyC"
    case d = "KeyD"
    case e = "KeyE"
    case f = "KeyF"
    case g = "KeyG"
    case h = "KeyH"
    case i = "KeyI"
    case j = "KeyJ"
    case k = "KeyK"
    case l = "KeyL"
    case m = "KeyM"
    case n = "KeyN"
    case o = "KeyO"
    case p = "KeyP"
    case q = "KeyQ"
    case r = "KeyR"
    case s = "KeyS"
    case t = "KeyT"
    case u = "KeyU"
    case v = "KeyV"
    case w = "KeyW"
    case x = "KeyX"
    case y = "KeyY"
    case z = "KeyZ"

    case zero = "Digit0"
    case one = "Digit1"
    case two = "Digit2"
    case three = "Digit3"
    case four = "Digit4"
    case five = "Digit5"
    case six = "Digit6"
    case seven = "Digit7"
    case eight = "Digit8"
    case nine = "Digit9"

    case minus = "Minus"
    case equal = "Equal"
    case leftBracket = "BracketLeft"
    case rightBracket = "BracketRight"
    case backslash = "Backslash"
    case semicolon = "Semicolon"
    case quote = "Quote"
    case comma = "Comma"
    case period = "Period"
    case slash = "Slash"

    case tab = "Tab"
    case enter = "Enter"
    case space = "Space"
    case esc = "Escape"

    // Left-hand modifiers; the right-hand variants (ShiftRight, …) are unmapped.
    case shift = "ShiftLeft"
    case control = "ControlLeft"
    case alt = "AltLeft"

    case upKey = "ArrowUp"
    case downKey = "ArrowDown"
    case rightKey = "ArrowRight"
    case leftKey = "ArrowLeft"
}

public extension WebBrowserKeyboardInput {
    var keyboardInput: KeyboardInput {
        switch self {
        case .a: return .a
        case .b: return .b
        case .c: return .c
        case .d: return .d
        case .e: return .e
        case .f: return .f
        case .g: return .g
        case .h: return .h
        case .i: return .i
        case .j: return .j
        case .k: return .k
        case .l: return .l
        case .m: return .m
        case .n: return .n
        case .o: return .o
        case .p: return .p
        case .q: return .q
        case .r: return .r
        case .s: return .s
        case .t: return .t
        case .u: return .u
        case .v: return .v
        case .w: return .w
        case .x: return .x
        case .y: return .y
        case .z: return .z
        case .zero: return .zero
        case .one: return .one
        case .two: return .two
        case .three: return .three
        case .four: return .four
        case .five: return .five
        case .six: return .six
        case .seven: return .seven
        case .eight: return .eight
        case .nine: return .nine
        case .minus: return .minus
        case .equal: return .equal
        case .leftBracket: return .leftBracket
        case .rightBracket: return .rightBracket
        case .backslash: return .backslash
        case .semicolon: return .semicolon
        case .quote: return .quote
        case .comma: return .comma
        case .period: return .period
        case .slash: return .slash
        case .tab: return .tab
        case .enter: return .enter
        case .space: return .space
        case .esc: return .esc
        case .shift: return .shift
        case .control: return .control
        case .alt: return .alt
        case .upKey: return .upKey
        case .downKey: return .downKey
        case .rightKey: return .rightKey
        case .leftKey: return .leftKey
        }
    }
}
