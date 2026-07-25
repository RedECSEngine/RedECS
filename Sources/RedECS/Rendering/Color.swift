/// Values represented from 0 to 1
public struct Color: Equatable, Codable, Sendable {
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

    public init(hex: Int, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}

/// Hue in degrees [0, 360), saturation and value in [0, 1].
public struct HSVColor: Equatable, Sendable {
    public var hue: Double
    public var saturation: Double
    public var value: Double
    public var alpha: Double

    public init(hue: Double, saturation: Double, value: Double, alpha: Double = 1) {
        self.hue = hue
        self.saturation = saturation
        self.value = value
        self.alpha = alpha
    }
}

public extension Color {
    var hsv: HSVColor {
        let maxComponent = max(red, green, blue)
        let minComponent = min(red, green, blue)
        let delta = maxComponent - minComponent

        var hue: Double = 0
        if delta > 0 {
            if maxComponent == red {
                hue = 60 * ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxComponent == green {
                hue = 60 * ((blue - red) / delta + 2)
            } else {
                hue = 60 * ((red - green) / delta + 4)
            }
            if hue < 0 { hue += 360 }
        }

        return HSVColor(
            hue: hue,
            saturation: maxComponent == 0 ? 0 : delta / maxComponent,
            value: maxComponent,
            alpha: alpha
        )
    }

    init(hsv: HSVColor) {
        var hue = hsv.hue.truncatingRemainder(dividingBy: 360)
        if hue < 0 { hue += 360 }
        let saturation = min(1, max(0, hsv.saturation))
        let value = min(1, max(0, hsv.value))

        let chroma = value * saturation
        let huePrime = hue / 60
        let x = chroma * (1 - abs(huePrime.truncatingRemainder(dividingBy: 2) - 1))
        let m = value - chroma

        let rgb: (Double, Double, Double)
        switch huePrime {
        case ..<1: rgb = (chroma, x, 0)
        case ..<2: rgb = (x, chroma, 0)
        case ..<3: rgb = (0, chroma, x)
        case ..<4: rgb = (0, x, chroma)
        case ..<5: rgb = (x, 0, chroma)
        default:   rgb = (chroma, 0, x)
        }

        self.init(red: rgb.0 + m, green: rgb.1 + m, blue: rgb.2 + m, alpha: hsv.alpha)
    }

    func rotatingHue(by degrees: Double) -> Color {
        var hsv = self.hsv
        hsv.hue += degrees
        return Color(hsv: hsv)
    }
}

public extension Color {
    static let white: Color = .init(red: 1, green: 1, blue: 1, alpha: 1)
    static let grey: Color = .init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    static let black: Color = .init(red: 0, green: 0, blue: 0, alpha: 1)
    
    static let red: Color = .init(red: 1, green: 0, blue: 0, alpha: 1)
    static let green: Color = .init(red: 0, green: 1, blue: 0, alpha: 1)
    static let blue: Color = .init(red: 0, green: 0, blue: 1, alpha: 1)
    
    static let yellow: Color = .init(red: 1, green: 1, blue: 0, alpha: 1)
    static let pink: Color = .init(red: 1, green: 0, blue: 1, alpha: 1)
    static let cyan: Color = .init(red: 0, green: 1, blue: 1, alpha: 1)
    
    static let orange: Color = .init(hex: 0xff7700)
    
    static let clear: Color = .init(red: 0, green: 0, blue: 0, alpha: 0)
    
    static func random() -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1
        )
    }
    
    func withAlpha(_ alpha: Double) -> Color {
        Color(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}
