import RedECS
import RedECSRenderingComponents
import SpriteKit

public struct SpriteKitStaticTextureRenderingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout StaticTextureRenderingContext,
        delta: Double,
        environment: SpriteKitRenderingEnvironment
    ) -> GameEffect<StaticTextureRenderingContext, Never> {
        state.staticTextureRendering.forEach { (id, component) in
            guard component.lastSetTextureName != component.textureName else { return }
            guard let position = state.transform[id] else { return }
            
            let sprite: SKSpriteNode
            if let node = environment.renderer.scene.childNode(withName: id) as? SKSpriteNode {
                sprite = node
            } else {
                let node = SKSpriteNode()
                environment.renderer.scene.addChild(node)
                sprite = node
            }
            
            let texture = SKTexture(imageNamed: component.textureName)
            texture.filteringMode = .nearest
            sprite.anchorPoint = .zero
            sprite.texture = texture
            sprite.size = texture.size()
            sprite.position = .init(x: position.position.x, y: position.position.y)
            
            if let transform = state.transform[id] {
                sprite.zRotation = transform.rotate.degreesToRadians()
                sprite.position.x += transform.position.x
                sprite.position.y += transform.position.y
            }
            
            state.staticTextureRendering[id]?.lastSetTextureName = component.textureName
        }
        
        return .none
    }
}
