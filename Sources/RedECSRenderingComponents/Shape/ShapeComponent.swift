import Foundation
import RedECS
import SpriteKit
import RedECSBasicComponents
import Geometry
import GeometrySpriteKitExtensions

public struct ShapeComponent: GameComponent {
    enum CodingKeys: String, CodingKey {
        case entity
        case shape
    }

    public let entity: EntityId
    public let shape: Shape
    public let node: SKShapeNode
    
    public init(
        entity: EntityId,
        shape: Shape
    ) {
        self.entity = entity
        self.shape = shape
        self.node = SKShapeNode(path: shape.makeCGPath())
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.entity = try container.decode(EntityId.self, forKey: .entity)
        self.shape = try container.decode(Shape.self, forKey: .shape)
        self.node = SKShapeNode(path: shape.makeCGPath())
    }
    
    public func prepareForDestruction() {
        node.removeFromParent()
    }
}
