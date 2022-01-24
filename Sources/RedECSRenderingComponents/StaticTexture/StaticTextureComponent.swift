import RedECS
import SpriteKit

public struct StaticTextureComponent: GameComponent {
    public var entity: EntityId
    public var textureName: String
    public var lastSetTextureName: String?

    public init(
        entity: EntityId,
        textureName: String
    ) {
        self.entity = entity
        self.textureName = textureName
    }
}

public struct StaticTextureRenderingContext: GameState {
    public var entities: EntityRepository
    public var sprite: [EntityId: SpriteComponent]
    public var staticTextureRendering: [EntityId: StaticTextureComponent]
    public init(
        entities: EntityRepository,
        sprite: [EntityId: SpriteComponent],
        staticTextureRendering: [EntityId: StaticTextureComponent]
    ) {
        self.entities = entities
        self.sprite = sprite
        self.staticTextureRendering = staticTextureRendering
    }
}

public struct StaticTextureRenderingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout StaticTextureRenderingContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<StaticTextureRenderingContext, Never> {
        state.staticTextureRendering.forEach { (id, component) in
            guard component.lastSetTextureName != component.textureName else { return }
            guard let sprite = state.sprite[id] else {
                assertionFailure("Missing sprite component")
                return
            }
            let texture = SKTexture(imageNamed: component.textureName)
            texture.filteringMode = .nearest
            sprite.node.anchorPoint = .zero
            sprite.node.texture = texture
            sprite.node.size = texture.size()
            state.staticTextureRendering[id]?.lastSetTextureName = component.textureName
        }
        return .none
    }
}
