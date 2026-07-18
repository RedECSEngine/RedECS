import Geometry

/// HUD space is top-left origin, y-down: `top` is 0 and `bottom` is `height`.

public enum HorizontalAlignment: Equatable, Sendable {
    case leading
    case center
    case trailing

    public func value(in width: Double) -> Double {
        switch self {
        case .leading: return 0
        case .center: return width / 2
        case .trailing: return width
        }
    }
}

public enum VerticalAlignment: Equatable, Sendable {
    case top
    case center
    case bottom

    public func value(in height: Double) -> Double {
        switch self {
        case .top: return 0
        case .center: return height / 2
        case .bottom: return height
        }
    }
}

public struct Alignment: Equatable, Sendable {
    public var horizontal: HorizontalAlignment
    public var vertical: VerticalAlignment

    public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public static let center = Self(horizontal: .center, vertical: .center)
    public static let leading = Self(horizontal: .leading, vertical: .center)
    public static let trailing = Self(horizontal: .trailing, vertical: .center)
    public static let top = Self(horizontal: .center, vertical: .top)
    public static let topLeading = Self(horizontal: .leading, vertical: .top)
    public static let topTrailing = Self(horizontal: .trailing, vertical: .top)
    public static let bottom = Self(horizontal: .center, vertical: .bottom)
    public static let bottomLeading = Self(horizontal: .leading, vertical: .bottom)
    public static let bottomTrailing = Self(horizontal: .trailing, vertical: .bottom)

    public func point(for size: Size) -> Point {
        Point(
            x: horizontal.value(in: size.width),
            y: vertical.value(in: size.height)
        )
    }

    /// The offset that places a child of `childSize` inside a parent of
    /// `parentSize` so both alignment points coincide.
    public func offset(forChild childSize: Size, in parentSize: Size) -> Point {
        let parentPoint = point(for: parentSize)
        let childPoint = point(for: childSize)
        return Point(x: parentPoint.x - childPoint.x, y: parentPoint.y - childPoint.y)
    }
}
