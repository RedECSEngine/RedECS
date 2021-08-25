import Foundation
import SpriteKit

public struct Animation {
    public let name: String
    public let frames: [AnimationFrame]
}

public struct AnimationFrame {
    public let texture: SKTexture
    public let duration: Double
}

public struct AnimationJSON: Codable {
    public struct Frame: Codable {
        var suffix: String
        var time: Double
    }
    public struct Variant: Codable {
        var name: String
    }
    public var name: String
    public var frames: [Frame]
    public var variants: [Variant]?
}

public extension AnimationDictionary {
    enum Error: Swift.Error {
        case fileNotFound
        case fileLoadFailure
        case fileDecodeFailure
    }
}

public struct AnimationDictionary {
    private let atlasName: String
    private let atlas: SKTextureAtlas
    private var dict: [String: Animation]!

    public subscript(index: String) -> Animation? {
        dict[index]
    }

    public init(atlasName: String, atlas: SKTextureAtlas) throws {
        guard let path = Bundle.main.path(forResource: atlasName, ofType: "json") else {
            throw Error.fileNotFound
        }

        let url = URL(fileURLWithPath: path)

        guard let jsonData = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            throw Error.fileLoadFailure
        }

        guard let animations = try? JSONDecoder().decode([String: AnimationJSON].self, from: jsonData) else {
            throw Error.fileDecodeFailure
        }

        self.atlasName = atlasName
        self.atlas = atlas
        dict = animations.reduce([:], animationTransform)
    }

    public func animationTransform(_ prev: [String: Animation], current: (key: String, value: AnimationJSON)) -> [String: Animation] {
        let name = current.key
        let animationFrames = current.value.frames.map {
            frame -> AnimationFrame in

            let frameTextureName = atlasName + frame.suffix
            let texture = atlas.textureNamed(frameTextureName)
            texture.filteringMode = .nearest
            return AnimationFrame(texture: texture, duration: frame.time)
        }

        let animation = Animation(name: name, frames: animationFrames)
        var new = prev
        new[name] = animation

        if let variants = current.value.variants {
            variants.forEach { new[$0.name] = animation }
        }

        return new
    }
}
