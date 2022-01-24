import SpriteKit
import Geometry
import RedECS
import RedECSBasicComponents

public struct SpriteAnimatingContext: GameState {
    public var entities: EntityRepository = .init()
    public var sprite: [EntityId: SpriteComponent]
    public var spriteAnimating: [EntityId: SpriteAnimatingComponent]
    
    public init(
        entities: EntityRepository = .init(),
        sprite: [EntityId : SpriteComponent],
        spriteAnimating: [EntityId : SpriteAnimatingComponent]
    ) {
        self.entities = entities
        self.sprite = sprite
        self.spriteAnimating = spriteAnimating
    }
}

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

public enum SpriteAnimatingAction: Equatable {
    case run(entityId: String, animationName: String, config: SpriteAnimationConfiguration = .default)
    case runOnce(animationId: UUID, entityId: String, animationName: String, config: SpriteAnimationConfiguration = .default)
    case animationComplete(UUID)
}

public struct SpriteAnimatingEnvironment {
    public var animations: [String: AnimationDictionary]
    public init(animations: [String: AnimationDictionary]) {
        self.animations = animations
    }
}

public struct SpriteAnimatingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout SpriteAnimatingContext,
        delta: Double,
        environment: SpriteAnimatingEnvironment
    ) -> GameEffect<SpriteAnimatingContext, SpriteAnimatingAction> {
        .none
    }
    
    public func reduce(
        state: inout SpriteAnimatingContext,
        action: SpriteAnimatingAction,
        environment: SpriteAnimatingEnvironment
    ) -> GameEffect<SpriteAnimatingContext, SpriteAnimatingAction> {
        switch action {
        case let .run(entityId, animationName, config):
            guard let spriteAnimating = state.spriteAnimating[entityId],
                  let sprite = state.sprite[entityId],
                  let animationsMap = environment.animations[spriteAnimating.atlasName] else {
                return .none
            }
            runAnimationForever(sprite: sprite.node, name: animationName, animationsMap: animationsMap, config: config)
        case let .runOnce(animationId, entityId, animationName, config):
            guard let spriteAnimating = state.spriteAnimating[entityId],
                  let sprite = state.sprite[entityId],
                  let animationsMap = environment.animations[spriteAnimating.atlasName] else {
                return .none
            }
            return .deferred(.init { resolver in
                runAnimationOnce(
                    sprite: sprite.node,
                    name: animationName,
                    animationsMap: animationsMap,
                    config: config
                ) {
                    resolver(.success(.game(.animationComplete(animationId))))
                }
            })
        case .animationComplete:
            break
        }
        return .none
    }
    
    public func runAnimationOnce(
        sprite: SKSpriteNode,
        name: String,
        animationsMap: AnimationDictionary,
        config: SpriteAnimationConfiguration,
        completion: (() -> Void)? = nil
    ) {
        let action = actionForAnimation(name: name, animationsMap: animationsMap)
        let completionAction = SKAction.run { completion?() }
        let combinedAction = SKAction.sequence([
            action,
            completionAction
        ])
        sprite.xScale = config.flipX ? -abs(sprite.xScale) : abs(sprite.xScale)
        sprite.yScale = config.flipY ? -abs(sprite.yScale) : abs(sprite.yScale)
        sprite.run(combinedAction, withKey: name)
    }
    
    public func runAnimationForever(
        sprite: SKSpriteNode,
        name: String,
        animationsMap: AnimationDictionary,
        config: SpriteAnimationConfiguration
    ) {
        let action = actionForAnimation(name: name, animationsMap: animationsMap)
        sprite.xScale = config.flipX ? -abs(sprite.xScale) : abs(sprite.xScale)
        sprite.yScale = config.flipY ? -abs(sprite.yScale) : abs(sprite.yScale)
        sprite.run(.repeatForever(action), withKey: "name")
    }
    
    fileprivate func actionForAnimation(name: String, animationsMap: AnimationDictionary) -> SKAction {
        guard let animation = animationsMap[name] else {
            fatalError("Can not find animation by name \(name)")
        }
        let actions = animation.frames.map {
            animationFrame -> SKAction in
            SKAction.animate(with: [animationFrame.texture], timePerFrame: animationFrame.duration)
        }
        return SKAction.sequence(actions)
    }
}
