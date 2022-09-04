import Geometry
import GeometryAlgorithms

public struct LabelComponent: GameComponent {
    public let entity: EntityId
    public var font: String
    public var text: String
    
    // TODO: color support
    
    public init(entity: EntityId) {
        self = .init(entity: entity, font: "", text: "")
    }
    
    public init(entity: EntityId, font: String, text: String) {
        self.entity = entity
        self.font = font
        self.text = text
    }
}

extension LabelComponent: RenderableComponent {
    public func renderGroups(
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
//                    origin: .init(x: currentOffsetX, y: -(characterData.height - characterData.yoffset)),
                    //center: .init(x: currentOffsetX - (characterData.width / 2), y: characterData.height + characterData.yoffset),
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
                    zIndex: transform.zIndex
                )
            ]
        } catch {
           return []
        }
    }
}
