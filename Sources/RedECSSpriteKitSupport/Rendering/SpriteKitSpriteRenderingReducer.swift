import Foundation
import SpriteKit
import RedECS
import RedECSRenderingComponents

public struct SpriteKitSpriteRenderingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout SpriteRenderingContext,
        delta: Double,
        environment: SpriteKitRenderingEnvironment
    ) -> GameEffect<SpriteRenderingContext, Never> {
        state.sprite.forEach { (id, shapeComponent) in
            guard let transform = state.transform[id] else { return }
            
            let sprite: SKNode
            if let node = environment.renderer.scene.childNode(withName: id) {
                sprite = node
            } else {
                let node = SKSpriteNode()
                environment.renderer.scene.addChild(node)
                sprite = node
            }
            
            sprite.position = .init(x: transform.position.x, y: transform.position.y)
            if let transform = state.transform[id] {
                sprite.zRotation = transform.rotate.degreesToRadians()
                sprite.position.x += transform.position.x
                sprite.position.y += transform.position.y
            }
        }
        return .none
    }
}
