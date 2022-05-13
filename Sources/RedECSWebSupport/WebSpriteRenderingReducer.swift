import RedECS
import RedECSRenderingComponents

public struct WebSpriteRenderingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout SpriteRenderingContext,
        delta: Double,
        environment: WebRenderingEnvironment
    ) -> GameEffect<SpriteRenderingContext, Never> {
        state.sprite.forEach { (id, shapeComponent) in
            guard let position = state.transform[id] else { return }
            // TODO: yo
            
//            let sprite: SKNode
//            if let node = environment.renderer.scene.child(withName: id) {
//                sprite = node
//            } else {
//                let node = SKSpriteNode()
//                environment.renderer.scene.addChild(shape)
//                sprite = node
//            }
//
//            sprite.position = .init(x: position.position.x, y: position.position.y)
//            if let transform = state.transform[id] {
//                sprite.zRotation = transform.rotate.degreesToRadians()
//                sprite.position.x += transform.translate.x
//                sprite.position.y += transform.translate.y
//            }
        }
        return .none
    }
}
