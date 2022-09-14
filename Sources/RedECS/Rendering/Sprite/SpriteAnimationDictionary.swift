public struct SpriteAnimationDictionary: Codable {
    public struct Animation: Codable, Equatable {
        public struct Frame: Codable, Equatable {
            public let name: String
            public let duration: Double
        }
        public let name: String
        public let frames: [Frame]
    }
    
    public enum Error: Swift.Error {
        case textureMapDoesNotContainAnyAnimations
    }
    
    public let name: String
    public private(set) var dict: [String: Animation]

    public subscript(index: String) -> Animation? {
        dict[index]
    }

    public init(name: String, textureMap: TextureMap) throws {
        self.name = name
        guard textureMap.meta.frameTags?.isEmpty == false else {
            throw Error.textureMapDoesNotContainAnyAnimations
        }
        var dict: [String: Animation] = [:]
        if let frameTags = textureMap.meta.frameTags {
            for frameTag in frameTags {
                let startIndex = frameTag.from
                let endIndex = frameTag.to
                let frames = textureMap.frames[(startIndex...endIndex)].map { frame in
                    Animation.Frame(name: frame.filename, duration: frame.duration ?? 0.16)
                }
                dict[frameTag.name] = Animation(name: frameTag.name, frames: frames)
            }
        }
        self.dict = dict
    }
}
