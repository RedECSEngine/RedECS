import Geometry
import GeometryAlgorithms

public extension BitmapFont {
    /// Glyph quads for one line of text, in the font's native scale.
    /// Geometry is y-up with the baseline math anchored to `common.base`;
    /// `size` is (sum of advances, tallest rendered glyph).
    struct TextLayout {
        public let triangles: [RenderTriangle]
        public let size: Size
    }

    /// The bounds `layoutText` would produce, without triangulating.
    func measure(_ text: String) -> Size {
        var currentOffsetX: Double = 0
        var maxHeight: Double = 0
        for character in text {
            guard let characterData = characterData(for: character) else { continue }
            if characterData.width > 0 && characterData.height > 0 {
                maxHeight = max(maxHeight, characterData.height)
            }
            currentOffsetX += characterData.xadvance
        }
        return Size(width: currentOffsetX, height: maxHeight)
    }

    /// Lays out one line of text as textured glyph quads against this font's
    /// atlas page. Unknown characters are skipped.
    func layoutText(_ text: String) throws -> TextLayout {
        var currentOffsetX: Double = 0
        var maxHeight: Double = 0
        var renderTriangles: [RenderTriangle] = []
        for character in text {
            guard let characterData = characterData(for: character) else { continue }
            guard characterData.width > 0 && characterData.height > 0 else {
                currentOffsetX += characterData.xadvance
                continue
            }
            let renderRect = Rect(
                x: currentOffsetX,
                y: (common.base - characterData.height - characterData.yoffset),
                width: characterData.width,
                height: characterData.height
            )
            let textureY = common.scaleH - (characterData.y + characterData.height)
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
        return TextLayout(
            triangles: renderTriangles,
            size: Size(width: currentOffsetX, height: maxHeight)
        )
    }

    /// The atlas page's texture id (the page file name without extension).
    var pageTextureName: String {
        page.file.split(separator: ".").dropLast().joined(separator: ".")
    }

    private func characterData(for character: Swift.Character) -> Character? {
        if let data = characterMap[String(character)] {
            return data
        }
        if character == " " {
            return characterMap["space"]
        }
        return nil
    }
}
