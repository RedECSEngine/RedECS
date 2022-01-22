import Foundation
import RedECS
import Geometry

public struct AsteroidComponent: GameComponent {
    public let entity: EntityId
    public let size: Int
    public let path: Path
    
    public init(entity: EntityId, size: Int) {
        self.entity = entity
        self.size = size
        self.path = Path(points: generateAsteroidEdges(size: size))
    }
}

private func generateAsteroidEdges(size: Int) -> [Point] {
    guard size > 0 else { return [] }
    
    let radius: Double = Double(size) * 7.5
    let radiusRange = (0.8)..<(1.2)
    
    let edgeCount: Int = size * 3
    let angleIncrement = 360 / Double(edgeCount)
    let angleRange = (angleIncrement-5)..<(angleIncrement+5)
    
    var points: [Point] = []
    var angle: Double = 0
    for _ in 0..<edgeCount {
        let edgeRadius = radius * Double.random(in: radiusRange)
        let x = edgeRadius * cos(angle.degreesToRadians())
        let y = edgeRadius * sin(angle.degreesToRadians())
        points.append(Point(x: x, y: y))
        angle += Double.random(in: angleRange)
    }
    
    return points
}
