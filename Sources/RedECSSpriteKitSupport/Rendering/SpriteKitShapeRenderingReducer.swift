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
            
            let shape: SKShapeNode
            if let shapeNode = environment.renderer.scene.childNode(withName: id) as? SKShapeNode {
                shape = shapeNode
            } else {
                let shapeNode = SKShapeNode(path: shapeComponent.shape.makeCGPath())
                shapeNode.name = id
              
                environment.renderer.scene.addChild(shapeNode)
                shape = shapeNode
            }
            
            shape.fillColor = .init(
                red: shapeComponent.fillColor.red,
                green: shapeComponent.fillColor.green,
                blue: shapeComponent.fillColor.blue,
                alpha: 1
            )
            shape.position = .init(x: transform.position.x, y: transform.position.y)
            shape.zRotation = transform.rotate.degreesToRadians()
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
