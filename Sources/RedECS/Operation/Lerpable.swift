import Geometry

/// A value an operation can interpolate.
public protocol Lerpable: Codable, Equatable {
    /// `t` is the eased progress in 0...1. Must return exactly `b` at `t == 1`,
    /// so a lerp lands on its target rather than drifting near it.
    static func lerp(_ a: Self, _ b: Self, _ t: Double) -> Self
    /// Used by `.by(_:)` to resolve a relative target against the captured start.
    static func offset(_ a: Self, by b: Self) -> Self
}

extension Double: Lerpable {
    public static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
    public static func offset(_ a: Double, by b: Double) -> Double { a + b }
}

extension Int: Lerpable {
    /// Rounds to nearest, so the value moves in whole steps and still arrives
    /// exactly on `b` at `t == 1`.
    public static func lerp(_ a: Int, _ b: Int, _ t: Double) -> Int {
        Int((Double(a) + (Double(b) - Double(a)) * t).rounded())
    }
    public static func offset(_ a: Int, by b: Int) -> Int { a + b }
}

extension Point: Lerpable {
    public static func lerp(_ a: Point, _ b: Point, _ t: Double) -> Point { a + (b - a) * t }
    public static func offset(_ a: Point, by b: Point) -> Point { a + b }
}

extension Size: Lerpable {
    public static func lerp(_ a: Size, _ b: Size, _ t: Double) -> Size {
        Size(
            width: Double.lerp(a.width, b.width, t),
            height: Double.lerp(a.height, b.height, t)
        )
    }
    public static func offset(_ a: Size, by b: Size) -> Size {
        Size(width: a.width + b.width, height: a.height + b.height)
    }
}

extension Color: Lerpable {
    public static func lerp(_ a: Color, _ b: Color, _ t: Double) -> Color {
        Color(
            red: Double.lerp(a.red, b.red, t),
            green: Double.lerp(a.green, b.green, t),
            blue: Double.lerp(a.blue, b.blue, t),
            alpha: Double.lerp(a.alpha, b.alpha, t)
        )
    }
    public static func offset(_ a: Color, by b: Color) -> Color {
        Color(
            red: a.red + b.red,
            green: a.green + b.green,
            blue: a.blue + b.blue,
            alpha: a.alpha + b.alpha
        )
    }
}
