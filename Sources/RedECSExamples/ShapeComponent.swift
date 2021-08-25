import Foundation
import RedECS
import SpriteKit
import RedECSBasicComponents

public struct ShapeComponent: GameComponent {
    enum CodingKeys: String, CodingKey {
        case entity
        case radius
    }

    public let entity: EntityId
    public let radius: CGFloat
    public let node: SKShapeNode
    
    public init(
        entity: EntityId,
        radius: CGFloat
    ) {
        self.entity = entity
        self.radius = radius
        self.node = SKShapeNode(circleOfRadius: radius)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.entity = try container.decode(EntityId.self, forKey: .entity)
        self.radius = try container.decode(CGFloat.self, forKey: .radius)
        self.node = SKShapeNode(circleOfRadius: radius)
    }
    
    public func prepareForDestruction() {
        node.removeFromParent()
    }
}

public struct ShapeRenderingReducer: Reducer {
    public init() {}
    public func reduce(state: inout ExampleGameState, delta: Double, environment: ExampleGameEnvironment) -> GameEffect<ExampleGameState, Never> {
        state.shape.forEach { (id, shape) in
            guard let position = state.position[id] else { return }
            
            if shape.node.parent == nil {
                shape.node.fillColor = .init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
                environment.renderer.addChild(shape.node)
            }
            
            shape.node.position = .init(x: position.point.x, y: position.point.y)
        }
        return .none
    }
}
