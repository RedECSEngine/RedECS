import Foundation
import RedECS

struct Point: Codable, Equatable {
    var x: Double
    var y: Double
    
    static let zero = Point(x: 0, y: 0)
}

struct TestPositionComponent: GameComponent {
    var entity: EntityId
    private var position: Point
    
    var x: Double {
        get { position.x }
        set { position.x = newValue }
    }
    
    var y: Double {
        get { position.y }
        set { position.y = newValue }
    }
    
    init(entity: EntityId, position: Point) {
        self.entity = entity
        self.position = position
    }
}
