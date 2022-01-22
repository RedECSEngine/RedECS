import Foundation
import RedECS
import Geometry

public struct ShipComponent: GameComponent {
    public let entity: EntityId
    public let path: Path
    
    public init(entity: EntityId) {
        self.entity = entity
        self.path = Path(points: [
            .init(x: -10, y: 0),
            .init(x: 0, y: 20),
            .init(x: 10, y: 0),
            .init(x: 0, y: 6),
        ])
    }
}
