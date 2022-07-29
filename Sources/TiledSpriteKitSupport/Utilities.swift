import Foundation
import SpriteKit

func makeImageTileDictionary(
    name: String,
    imageData: Data,
    tileWidth: Double,
    tileHeight: Double
) -> [String: Any]? {
    guard let image = NSImage(data: imageData) else {
        return nil
    }
    
    var images = [String: Any]()
    let cols = Int(image.size.width / tileWidth)
    let rows = Int(image.size.height / tileHeight)
    for r in 0..<rows {
        for c in 0..<cols {
            let rect = CGRect(
                x: (Double(c) * tileWidth),
                y: (Double(r) * tileHeight),
                width: tileWidth,
                height: tileHeight
            )
            let tileImage = crop(nsImage: image, rect: rect)
            let id = "\(name)-\((r * cols) + c + 1)"
            images[id] = tileImage
        }
    }
    return images
}

func makeTextureAtlas(
    name: String,
    imageData: Data,
    tileWidth: Double,
    tileHeight: Double
) -> SKTextureAtlas? {
    guard let images = makeImageTileDictionary(
        name: name,
        imageData: imageData,
        tileWidth: tileWidth,
        tileHeight: tileHeight
    ) else {
        return nil
    }
    return .init(dictionary: images)
}

func makeTileset(
    name: String,
    imageData: Data,
    tileWidth: Double,
    tileHeight: Double
) -> SKTileSet? {
    guard let atlas = makeTextureAtlas(
        name: name,
        imageData: imageData,
        tileWidth: tileWidth,
        tileHeight: tileHeight
    ) else {
        return nil
    }
    let groups = atlas.textureNames.map { textureName -> SKTileGroup in
        let group = SKTileGroup(
            tileDefinition: SKTileDefinition(
                texture: atlas.textureNamed(textureName)
            )
        )
        group.name = textureName
        return group
    }
    let set = SKTileSet(tileGroups: groups)
    set.name = name
    return set
}

fileprivate func crop(nsImage: NSImage, rect: CGRect) -> NSImage {
    let cgImage = (nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)?.cropping(to: rect))!

    let size = NSSize(width: rect.width, height: rect.height)
    return NSImage(cgImage: cgImage, size: size)
}
