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

    public func contains(_ point: Point, whenTransformedBy matrix: Matrix3? = nil) -> Bool {
        guard let matrix = matrix else {
            return rect.contains(point)
        }
        let triangles = (try? triangulate()) ?? []
        for triangle in triangles where triangle.multiplyingMatrix(matrix).contains(point) {
            return true
        }
        return false
    }
}
