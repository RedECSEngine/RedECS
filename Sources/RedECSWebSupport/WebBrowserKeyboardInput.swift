import RedECSBasicComponents

public enum WebBrowserKeyboardInput: String, Codable {
    case a = "KeyA"
    case s = "KeyS"
    case d = "KeyD"
    case q = "KeyQ"
    case w = "KeyW"
    case e = "KeyE"
    
    case enter = "Enter"
    case space = "Space"
    case esc = "Escape"
    
    case upKey = "ArrowUp"
    case downKey = "ArrowDown"
    case rightKey = "ArrowRight"
    case leftKey = "ArrowLeft"
}

public extension WebBrowserKeyboardInput {
    var keyboardInput: KeyboardInput {
        switch self {
        case .a:
            return .a
        case .s:
            return .s
        case .d:
            return .d
        case .q:
            return .q
        case .w:
            return .w
        case .e:
            return .e
        case .enter:
            return .enter
        case .space:
            return .space
        case .esc:
            return .esc
        case .upKey:
            return .upKey
        case .downKey:
            return .downKey
        case .rightKey:
            return .rightKey
        case .leftKey:
            return .leftKey
        }
    }
}
