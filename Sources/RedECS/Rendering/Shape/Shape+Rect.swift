import Geometry
import GeometryAlgorithms

extension Shape {
    public var rect: Rect {
        switch self {
        case .rect(let r):
            return r
        case .triangle(let t):
            return GeometryAlgorithms.calculateContainingRect(of: t.points)
        case .circle(let c):
            return Rect(center: c.center, size: c.size)
        case .polygon(let p):
            return GeometryAlgorithms.calculateContainingRect(of: p.points)
        }
    }
}
