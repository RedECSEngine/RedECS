import RedECS
import Geometry

public struct ShapeComponent: GameComponent {
    enum CodingKeys: String, CodingKey {
        case entity
        case shape
    }

    public let entity: EntityId
    public let shape: Shape
    
    public init(
        entity: EntityId,
        shape: Shape
    ) {
        self.entity = entity
        self.shape = shape
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.entity = try container.decode(EntityId.self, forKey: .entity)
        self.shape = try container.decode(Shape.self, forKey: .shape)
    }
}
