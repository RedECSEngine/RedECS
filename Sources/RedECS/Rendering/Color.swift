/// Values represented from 0 to 1
public struct Color: Equatable, Codable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double
    
    public init(
        red: Double,
        green: Double,
        blue: Double,
        alpha: Double
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var hexValue: Int {
        let rInt = Int(min(255, max(0, red * 255))) << 16
        let gInt = Int(min(255, max(0, green * 255))) << 8
        let bInt = Int(min(255, max(0, blue * 255)))
        return rInt + gInt + bInt
    }
    
    init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0,
            alpha: 1.0
        )
    }
    
    init(hex: Int) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF
        )
    }
}

public extension Color {
    static let white: Color = .init(red: 1, green: 1, blue: 1, alpha: 1)
    static let grey: Color = .init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    static let black: Color = .init(red: 0, green: 0, blue: 0, alpha: 1)
    static let red: Color = .init(hex: 0xff0000)
    static let green: Color = .init(red: 0, green: 1, blue: 0, alpha: 1)
    static let blue: Color = .init(red: 0, green: 0, blue: 1, alpha: 1)
    
    static let clear: Color = .init(red: 0, green: 0, blue: 0, alpha: 0)
    
    static func random() -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1
        )
    }
}
