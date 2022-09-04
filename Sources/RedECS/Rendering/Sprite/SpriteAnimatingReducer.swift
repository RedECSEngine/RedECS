import Geometry

public struct SpriteAnimationConfiguration: Codable, Equatable {
    public static var `default` = SpriteAnimationConfiguration()
    public var flipX: Bool
    public var flipY: Bool
    public init(
        flipX: Bool = false,
        flipY: Bool = false
    ) {
        self.flipX = flipX
        self.flipY = flipY
    }
}

public enum SpriteAnimatingAction: Equatable & Codable {
    case run(
        entityId: String,
        animationName: String,
        config: SpriteAnimationConfiguration = .default
    )
    case runOnce(
        animationId: String,
        entityId: String,
        animationName: String,
        config: SpriteAnimationConfiguration = .default
    )
    case animationComplete(String)
}

public struct SpriteAnimatingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout SpriteContext,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<SpriteContext, SpriteAnimatingAction> {
        var effects: [GameEffect<SpriteContext, SpriteAnimatingAction>] = []
        state.sprite.forEach { (id, spriteComponent) in
            var sprite = spriteComponent
            if let completedAnimationId = sprite.applyDelta(delta) {
                effects.append(.game(.animationComplete(completedAnimationId)))
            }
            state.sprite[id] = sprite
        }
        return .many(effects)
    }
    
    public func reduce(
        state: inout SpriteContext,
        action: SpriteAnimatingAction,
        environment: RenderingEnvironment
    ) -> GameEffect<SpriteContext, SpriteAnimatingAction> {
        switch action {
        case let .run(entityId, animationName, config):
            guard let sprite = state.sprite[entityId],
                  let animationDict = environment.resourceManager.animationsForTexture(sprite.texture.textureId),
                  let animation = animationDict[animationName] else {
                return .none
            }
            
            state.sprite[entityId]?.runAnimation(animation, animationId: nil, repeatsForever: true)
            state.transform[entityId]?.scale.x = config.flipX ? -1 : 1
        case let .runOnce(animationId, entityId, animationName, config):
            guard let sprite = state.sprite[entityId],
                  let animationDict = environment.resourceManager.animationsForTexture(sprite.texture.textureId),
                  let animation = animationDict[animationName] else {
                return .none
            }
            state.sprite[entityId]?.runAnimation(animation, animationId: animationId, repeatsForever: false)
            state.transform[entityId]?.scale.x = config.flipX ? -1 : 1
        case .animationComplete:
            break
        }
        return .none
    }
}
