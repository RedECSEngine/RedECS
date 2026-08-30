import Geometry
import GeometryAlgorithms
import TiledInterpreter

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

public enum SpriteType: Codable, Equatable {
    case texture(TextureReference)
    case shape(Shape)
    case label(font: String, text: String)
    case tileMap(TiledMapJSON)
}

public struct SpriteComponent: GameComponent {
    public var entity: EntityId
    public var type: SpriteType?
    public var animation: SpriteAnimation?

    public var fillColor: Color = .clear
    public var opacity: Double = 1
    public var tileAnimationTime: Double = 0
    public var shader: ShaderEffect? = nil // fragment effect applied to this sprite's draws; nil = passthrough
    /// Where this sprite's content hangs on its transform's frame, from 0 to 1.
    /// The transform's position is where the anchor point of the content sits,
    /// and rotation/scale pivot around it. Content only — children of the
    /// entity attach to the frame itself.
    public var anchorPoint: Point = .init(x: 0.5, y: 0.5)

    public init(entity: EntityId) {
        self.init(entity: entity, type: nil)
    }

    public init(
        entity: EntityId,
        type: SpriteType?,
        anchorPoint: Point = .init(x: 0.5, y: 0.5)
    ) {
        self.entity = entity
        self.type = type
        self.setAnchorPoint(anchorPoint)
    }

    /// Clamps values between 0 and 1. A value of 0.5 for both x and y means center
    public mutating func setAnchorPoint(_ anchorPoint: Point) {
        self.anchorPoint = .init(
            x: max(0, min(1, anchorPoint.x)),
            y: max(0, min(1, anchorPoint.y))
        )
    }

    /// The model matrix for drawing content of `containerSize` in `transform`'s
    /// frame, offset so the anchor point of the content lands on the frame's
    /// position.
    public func contentMatrix(transform: TransformComponent, containerSize: Size) -> Matrix3 {
        transform.matrix()
            .translatedBy(
                tx: -anchorPoint.x * containerSize.width,
                ty: -anchorPoint.y * containerSize.height
            )
    }
    
    public mutating func runAnimation(
        _ animation: SpriteAnimationDictionary.Animation,
        animationId: String?,
        repeatsForever: Bool
    ) {
        guard let type = type,
                case let .texture(texture) = type else { return }
        self.animation = SpriteAnimation(
            id: animationId,
            animation: animation,
            currentTime: 0,
            currentFrame: 0,
            repeatsForever: repeatsForever
        )
        self.type = .texture(TextureReference(
            textureId: texture.textureId,
            frameId: animation.frames[0].name
        ))
    }
    
    public mutating func applyDelta(_ delta: Double) -> CompletedAnimationId? {
        if case .tileMap? = type {
            tileAnimationTime += delta * 1000
            return nil
        }
        guard var runningAnimation = animation else {
            return nil
        }
        guard let type = type,
                case let .texture(texture) = type else { return nil }
        
        runningAnimation.currentTime += delta
        
        guard runningAnimation.needsNextFrame else {
            animation = runningAnimation
            return nil
        }
        
        runningAnimation.currentTime = 0
        runningAnimation.currentFrame += 1
        let isPastFinalFrame = (runningAnimation.currentFrame >= runningAnimation.animation.frames.count)
        if isPastFinalFrame && !runningAnimation.repeatsForever {
            self.type = .texture(TextureReference(
                textureId: texture.textureId,
                frameId: runningAnimation.animation.frames[0].name
            ))
            animation = nil
            return runningAnimation.id
        } else if isPastFinalFrame {
            runningAnimation.currentFrame = 0
        }
        
        animation = runningAnimation
        self.type = .texture(TextureReference(
            textureId: texture.textureId,
            frameId: runningAnimation.animation.frames[runningAnimation.currentFrame].name
        ))
        return nil
    }
}

public extension SpriteComponent {
    var textureId: TextureId? {
        if case let .texture(texture) = type {
            return texture.textureId
        }
        return nil
    }
    
    mutating func setTexture(_ texture: TextureReference) {
        type = .texture(texture)
    }
    
    mutating func setFrame(_ frameId: String?) {
        guard let textureId = textureId else { return }
        type = .texture(.init(textureId: textureId, frameId: frameId))
    }
}

extension SpriteComponent: RenderableComponent {
    public func renderGroups(
        cameraMatrix: Matrix3,
        transform: TransformComponent,
        resourceManager: ResourceManager
    ) -> [RenderGroup] {
        
        guard let type = type else { return [] }
        
        switch type {
        case .texture(let texture):
            return textureRenderGroups(
                texture: texture,
                cameraMatrix: cameraMatrix,
                transform: transform,
                resourceManager: resourceManager
            )
        case .shape(let shape):
            guard let triangulated = try? shape.triangulate() else {
                return []
            }
            let triangles = triangulated.enumerated()
                .map { (i, triangle) -> RenderTriangle in
                    RenderTriangle(triangle: triangle)
                }
            let matrix = contentMatrix(transform: transform, containerSize: shape.rect.size)
            return [
                RenderGroup(
                    triangles: triangles,
                    transformMatrix: matrix,
                    fragmentType: .color(fillColor),
                    zIndex: transform.zIndex,
                    shader: shader // carry the sprite's effect onto its group
                )
            ]
        case let .label(font, text):
            return labelRenderGroups(
                font: font,
                text: text,
                cameraMatrix: cameraMatrix,
                transform: transform,
                resourceManager: resourceManager
            )
        case let .tileMap(map):
           return tileMapRenderGroups(
               tileMap: map,
               cameraMatrix: cameraMatrix,
               transform: transform
           )
        }
    }
}

extension SpriteComponent {
    func labelRenderGroups(
        font: String,
        text: String,
        cameraMatrix: Matrix3,
        transform: TransformComponent,
        resourceManager: ResourceManager
    ) -> [RenderGroup] {
        guard let font = resourceManager.fonts[font] else {
            return []
        }
        do {
            let layout = try font.layoutText(text)
            return [
                RenderGroup(
                    triangles: layout.triangles,
                    transformMatrix: contentMatrix(
                        transform: transform,
                        containerSize: layout.size
                    ),
                    fragmentType: .texture(font.pageTextureName),
                    zIndex: transform.zIndex,
                    opacity: opacity,
                    shader: shader // e.g. tinting a label
                )
            ]
        } catch {
           return []
        }
    }
}

extension SpriteComponent {
    func textureRenderGroups(
        texture: TextureReference,
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
        if let frameId = texture.frameId {
            // A named frame that isn't in the atlas is always a bug; drawing
            // the whole sheet as a fallback painted sprite sheets over the map.
            guard let frameInfo = textureMap.frames.first(where: { $0.filename == frameId }) else {
                print("frame \(frameId) not found in texture \(texture.textureId); not rendering")
                return []
            }
            textureRect = Rect(
                x: frameInfo.frame.x,
                y: textureMap.meta.size.h - frameInfo.frame.y - frameInfo.frame.h,
                width: frameInfo.frame.w,
                height: frameInfo.frame.h
            )
        } else {
            // No frame requested: single-image textures draw whole.
            let size = textureMap.meta.size
            textureRect = Rect(x: 0, y: 0, width: size.w, height: size.h)
        }
        
        // Corner-origin like every other sprite type, so `contentMatrix`'s
        // anchor offset means the same thing for textures as for shapes.
        let renderRect = Rect(origin: .zero, size: textureRect.size)
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
                transformMatrix: contentMatrix(transform: transform, containerSize: renderRect.size),
                fragmentType: .texture(texture.textureId),
                zIndex: transform.zIndex,
                opacity: opacity,
                shader: shader // e.g. the hero's palette remap
            )
        ]
    }
}
