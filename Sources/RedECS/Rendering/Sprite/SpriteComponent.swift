import Geometry
import GeometryAlgorithms

public typealias CompletedAnimationId = String

public struct SpriteAnimation: Codable, Equatable {
    var id: String?
    var animation: SpriteAnimationDictionary.Animation
    var currentTime: Double
    var currentFrame: Int
    var repeatsForever: Bool
    
    var needsNextFrame: Bool {
        (animation.frames[currentFrame].duration / 1000) < currentTime
    }
}

public struct SpriteComponent: GameComponent {
    public var entity: EntityId
    public var texture: TextureReference
    public var animation: SpriteAnimation?
    public var opacity: Double = 1
    
    public init(entity: EntityId) {
        self.init(entity: entity, texture: .empty)
    }
    
    public init(
        entity: EntityId,
        texture: TextureReference = .empty
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
        if runningAnimation.repeatsForever == false {
            print(animation?.animation.name, runningAnimation.currentFrame)
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
            print("run once anim complete", animation?.animation.name)
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

extension SpriteComponent: RenderableComponent {
    public func renderGroups(
        cameraMatrix: Matrix3,
        transform: TransformComponent,
        resourceManager: ResourceManager
    ) -> [RenderGroup] {
        let projectedPosition = transform.position.multiplyingMatrix(cameraMatrix)
        if abs(projectedPosition.x) > 1.05 || abs(projectedPosition.y) > 1.05 {
            return []
        }
        
        guard let textureMap = resourceManager.getTexture(textureId: texture.textureId) else {
            return []
        }
        let textureRect: Rect
        if let frameId = texture.frameId,
            let frameInfo = textureMap.frames.first(where: { $0.filename == frameId }) {
            textureRect = Rect(
                x: frameInfo.frame.x,
                y: textureMap.meta.size.h - frameInfo.frame.y - frameInfo.frame.h,
                width: frameInfo.frame.w,
                height: frameInfo.frame.h
            )
        } else {
            print("using full texture, no frame info", textureMap.frames)
            let size = textureMap.meta.size
            textureRect = Rect(x: 0, y: 0, width: size.w, height: size.h)
        }
        
        let renderRect = Rect(center: .zero, size: textureRect.size)
        let topRenderTri = RenderTriangle(
            triangle: Triangle(
                a: Point(x: renderRect.minX, y: renderRect.maxY),
                b: Point(x: renderRect.maxX, y: renderRect.minY),
                c: Point(x: renderRect.maxX, y: renderRect.maxY)
            ),
            textureTriangle: Triangle(
                a: Point(x: textureRect.minX, y: textureRect.maxY),
                b: Point(x: textureRect.maxX, y: textureRect.minY),
                c: Point(x: textureRect.maxX, y: textureRect.maxY)
            )
        )
        let bottomRenderTri = RenderTriangle(
            triangle: Triangle(
                a: Point(x: renderRect.minX, y: renderRect.minY),
                b: Point(x: renderRect.maxX, y: renderRect.minY),
                c: Point(x: renderRect.minX, y: renderRect.maxY)
            ),
            textureTriangle: Triangle(
                a: Point(x: textureRect.minX, y: textureRect.minY),
                b: Point(x: textureRect.maxX, y: textureRect.minY),
                c: Point(x: textureRect.minX, y: textureRect.maxY)
            )
        )
        return [
            RenderGroup(
                triangles: [topRenderTri, bottomRenderTri],
                transformMatrix: transform.matrix(containerSize: renderRect.size),
                fragmentType: .texture(texture.textureId),
                zIndex: transform.zIndex,
                opacity: opacity
            )
        ]
    }
}
