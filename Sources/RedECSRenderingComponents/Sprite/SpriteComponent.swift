import RedECS

public typealias CompletedAnimationId = String

public struct SpriteAnimation: Codable, Equatable {
    var id: String?
    var animation: SpriteAnimationDictionary.Animation
    var currentTime: Double
    var currentFrame: Int
    var repeatsForever: Bool
    
    var needsNextFrame: Bool {
        animation.frames[currentFrame].duration < currentTime
    }
}

public struct SpriteComponent: GameComponent {
    public var entity: EntityId
    public var texture: TextureReference
    public var animation: SpriteAnimation?
    
    public init(
        entity: EntityId,
        texture: TextureReference
    ) {
        self.entity = entity
        self.texture = texture
    }
    
    public mutating func runAnimation(
        _ animation: SpriteAnimationDictionary.Animation,
        animationId: String?,
        repeatsForever: Bool
    ) {
        self.animation = SpriteAnimation(
            id: animationId,
            animation: animation,
            currentTime: 0,
            currentFrame: 0,
            repeatsForever: repeatsForever
        )
        texture = TextureReference(
            textureId: texture.textureId,
            frameId: animation.frames[0].name
        )
    }
    
    public mutating func applyDelta(_ delta: Double) -> CompletedAnimationId? {
        guard var runningAnimation = animation else {
            return nil
        }
        
        runningAnimation.currentTime += delta
        
        guard runningAnimation.needsNextFrame else {
            animation = runningAnimation
            return nil
        }
        
        runningAnimation.currentTime = 0
        runningAnimation.currentFrame += 1
        let isPastFinalFrame = (runningAnimation.currentFrame >= runningAnimation.animation.frames.count)
        if isPastFinalFrame && !runningAnimation.repeatsForever {
            texture = TextureReference(
                textureId: texture.textureId,
                frameId: runningAnimation.animation.frames[0].name
            )
            animation = nil
            return runningAnimation.id
        } else if isPastFinalFrame {
            runningAnimation.currentFrame = 0
        }
        
        animation = runningAnimation
        texture = TextureReference(
            textureId: texture.textureId,
            frameId: runningAnimation.animation.frames[runningAnimation.currentFrame].name
        )
        return nil
    }
}
