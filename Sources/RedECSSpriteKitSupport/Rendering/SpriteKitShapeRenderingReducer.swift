import Foundation
import SpriteKit
import RedECS
import RedECSRenderingComponents
import Geometry
import GeometrySpriteKitExtensions

public struct SpriteKitShapeRenderingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout ShapeRenderingContext,
        delta: Double,
        environment: SpriteKitRenderingEnvironment
    ) -> GameEffect<ShapeRenderingContext, Never> {
        state.shape.forEach { (id, shapeComponent) in
            guard let transform = state.transform[id] else { return }
            
            let shape: SKNode
            if let shapeNode = environment.renderer.scene.childNode(withName: id) {
                shape = shapeNode
            } else {
                let shapeNode = SKShapeNode(path: shapeComponent.shape.makeCGPath())
                shapeNode.name = id
                shapeNode.fillColor = .init(
                    red: .random(in: 0...1),
                    green: .random(in: 0...1),
                    blue: .random(in: 0...1),
                    alpha: 1
                )
                environment.renderer.scene.addChild(shapeNode)
                shape = shapeNode
            }
            
            shape.position = .init(x: transform.position.x, y: transform.position.y)
            if let transform = state.transform[id] {
                shape.zRotation = transform.rotate.degreesToRadians()
                shape.position.x += transform.position.x
                shape.position.y += transform.position.y
            }
        }
        return .none
    }
    
    public func reduce(
        state: inout ShapeRenderingContext,
        entityEvent: EntityEvent,
        environment: SpriteKitRenderingEnvironment
    ) {
        guard case let .removed(id) = entityEvent,
              let node = environment.renderer.scene.childNode(withName: id) else { return }
        
        node.removeFromParent()
    }
}
