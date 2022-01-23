import Foundation
import RedECS
import Geometry

public struct AsteroidComponent: GameComponent {
    public let entity: EntityId
    public let size: Int
    public let path: Path
    
    var edges: Int {
        size * 4
    }
    
    var radius: Double {
        Double(size) * 7.5
    }
    
    var radiusRangeLow: Double = 0.8
    var radiusRangeHigh: Double = 1.2
    
    public init(entity: EntityId, size: Int, path: Path? = nil) {
        self.entity = entity
        self.size = size
        if let path = path {
            self.path = path
        } else {
            self.path = .init()
            self.createAsteroidPath()
        }
    }
    
    public func intersects(_ c: Circle, whenPositionedAt location: Point) -> Bool {
        guard c.intersects(Circle(center: location, radius: radius * radiusRangeHigh)) else {
            return false
        }
        
        if c.intersects(Circle(center: location, radius: radius * radiusRangeLow)) {
            return true
        } else {
            for i in (0..<path.points.count-1) {
                let line = Line(a: location + path.points[i], b: location + path.points[i + 1])
                if line.intersects(c) {
                    return true
                }
            }
            return false
        }
    }
    
    private mutating func createAsteroidPath() {
        let radiusRange = (radiusRangeLow)..<(radiusRangeHigh)
        let angleIncrement = 360 / Double(edges)
        let angleRange = (angleIncrement-5)..<(angleIncrement+5)
        
        var points: [Point] = []
        var angle: Double = 0
        for _ in 0..<edges {
            let edgeRadius = radius * Double.random(in: radiusRange)
            let x = edgeRadius * cos(angle.degreesToRadians())
            let y = edgeRadius * sin(angle.degreesToRadians())
            points.append(Point(x: x, y: y))
            angle += Double.random(in: angleRange)
        }
        self = .init(entity: entity, size: size, path: Path(points: points))
    }
}

