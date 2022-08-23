import Geometry
import GeometryAlgorithms

public struct ShapeComponent: GameComponent {
    public let entity: EntityId
    public var shape: Shape {
        didSet {
            triangulate()
        }
    }
    public var fillColor: Color
    
    public private(set) var triangles: [Triangle] = []
    
    public var rect: Rect {
        switch shape {
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
    
    public init(
        entity: EntityId,
        shape: Shape,
        fillColor: Color = .white
    ) {
        self.entity = entity
        self.shape = shape
        self.fillColor = fillColor
        
        triangulate()
    }

    private mutating func triangulate() {
        triangles = (try? shape.triangulate()) ?? []
    }
    
    public func contains(_ point: Point, whenTransformedBy matrix: Matrix3? = nil) -> Bool {
        if let matrix = matrix {
            for triangle in triangles {
                if triangle.multiplyingMatrix(matrix).contains(point) {
                    return true
                }
            }
            return false
        } else {
            return rect.contains(point)
        }
    }
    
}
