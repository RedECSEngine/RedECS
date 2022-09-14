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
    
    public init(entity: EntityId) {
        self.init(entity: entity, type: nil)
    }
    
    public init(
        entity: EntityId,
        type: SpriteType?
    ) {
        self.entity = entity
        self.type = type
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
            let matrix = transform.matrix(containerSize: shape.rect.size)
            return [
                RenderGroup(
                    triangles: triangles,
                    transformMatrix: matrix,
                    fragmentType: .color(fillColor),
                    zIndex: transform.zIndex
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
               transform: transform,
               resourceManager: resourceManager
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
        
        var currentOffsetX: Double = 0
        var maxHeight: Double = 0
        var renderTriangles: [RenderTriangle] = []
        do {
            for character in text {
                let characterData: BitmapFont.Character
                if let data = font.characterMap[String(character)] {
                    characterData = data
                } else if character == " ", let data = font.characterMap["space"] {
                    currentOffsetX += data.xadvance
                    continue
                } else {
                    continue
                }
                let renderRect = Rect(
                    x: currentOffsetX,
                    y: (font.common.base - characterData.height - characterData.yoffset),
                    width: characterData.width,
                    height: characterData.height
                )
                let textureY = font.common.scaleH - (characterData.y + characterData.height)
                let textureRect = Rect(
                    origin: .init(x: characterData.x, y: textureY),
                    size: Size(width: characterData.width, height: characterData.height)
                )
                let renderTris = try renderRect.triangulate()
                let textureTris = try textureRect.triangulate()
                for i in 0..<2 {
                    renderTriangles.append(
                        RenderTriangle(
                            triangle: renderTris[i],
                            textureTriangle: textureTris[i]
                        )
                    )
                }
                maxHeight = max(maxHeight, characterData.height)
                currentOffsetX += characterData.xadvance
            }
            let textureName = font.page.file.split(separator: ".").dropLast().joined(separator: ".")
            return [
                RenderGroup(
                    triangles: renderTriangles,
                    transformMatrix: transform.matrix(
                        containerSize: Size(width: currentOffsetX, height: maxHeight)
                    ),
                    fragmentType: .texture(textureName),
                    zIndex: transform.zIndex,
                    opacity: opacity
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

extension SpriteComponent {
    func tileMapRenderGroups(
        tileMap: TiledMapJSON,
        cameraMatrix: Matrix3,
        transform: TransformComponent,
        resourceManager: ResourceManager
    ) -> [RenderGroup] {
        let tileWidth = tileMap.tileWidth,
            tileHeight = tileMap.tileHeight,
            layerCols = tileMap.width,
            layerRows = tileMap.height,
            tileSize = Size(width: Double(tileWidth), height: Double(tileHeight))
        
        var renderGroups = [RenderGroup]()
        tileMap.tileLayers.enumerated().forEach { (i, layer) in
            guard let tileSetName = tileMap.tileSets.first?.source,
                  let tileSet = resourceManager.tileSets[tileSetName] else {
                return
            }
            
            let matrix = transform.matrix(containerSize: Size(
                width: tileMap.totalWidth,
                height: tileMap.totalHeight
            ))
            
            var renderTriangles: [RenderTriangle] = []
            
            for r in 0..<layerRows {
                for c in 0..<layerCols {
                    let rectForTile = Rect(
                        center: .init(
                            x: Double(c * tileWidth + tileWidth / 2),
                            y: Double(r * tileHeight + tileHeight / 2)
                        ),
                        size: tileSize
                    )
                    
                    let projectedPosition = rectForTile.center.multiplyingMatrix(cameraMatrix)
                    if abs(projectedPosition.x) > 1.125 || abs(projectedPosition.y) > 1.125 {
                        continue
                    }
                    
                    guard let tileIndex = layer.tileDataAt(column: c, row: r, flipY: true) else { continue }
                    
                    guard tileIndex != 0 else { continue } // empty
                    
                    let tileSetCol = (tileIndex) % tileSet.columns - 1
                    let tileSetRow = ((tileIndex) / tileSet.columns)
                    
                    let textureRect = Rect(
                        center: .init(
                            x: Double(tileSetCol * tileWidth + tileWidth / 2),
                            y: Double(tileSet.imageHeight) - Double(tileSetRow * tileHeight + tileHeight / 2)
                        ),
                        size: tileSize
                    )
                    
                    let topRenderTri = RenderTriangle(
                        triangle: Triangle(
                            a: Point(x: rectForTile.minX, y: rectForTile.maxY),
                            b: Point(x: rectForTile.maxX, y: rectForTile.minY),
                            c: Point(x: rectForTile.maxX, y: rectForTile.maxY)
                        ),
                        textureTriangle: Triangle(
                            a: Point(x: textureRect.minX, y: textureRect.maxY),
                            b: Point(x: textureRect.maxX, y: textureRect.minY),
                            c: Point(x: textureRect.maxX, y: textureRect.maxY)
                        )
                    )
                    let bottomRenderTri = RenderTriangle(
                        triangle: Triangle(
                            a: Point(x: rectForTile.minX, y: rectForTile.minY),
                            b: Point(x: rectForTile.maxX, y: rectForTile.minY),
                            c: Point(x: rectForTile.minX, y: rectForTile.maxY)
                        ),
                        textureTriangle: Triangle(
                            a: Point(x: textureRect.minX, y: textureRect.minY),
                            b: Point(x: textureRect.maxX, y: textureRect.minY),
                            c: Point(x: textureRect.minX, y: textureRect.maxY)
                        )
                    )
                    
                    renderTriangles.append(contentsOf: [topRenderTri, bottomRenderTri])
                }
            }
            
            guard !renderTriangles.isEmpty else {
                return
            }
            
            let textureId = tileSet.image.split(separator: ".").dropLast().joined(separator: ".")
            renderGroups.append(RenderGroup(
                triangles: renderTriangles,
                transformMatrix: matrix,
                fragmentType: .texture(textureId),
                zIndex: transform.zIndex
            ))
        }
        return renderGroups
    }
}
