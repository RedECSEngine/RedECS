import RedECS
public struct SpriteAnimationDictionary {
    public struct Animation {
        public struct Frame {
            public let name: String
            public let duration: Double
        }
        public let name: String
        public let frames: [Frame]
    }
    
    private let name: String
    private var dict: [String: Animation]

    public subscript(index: String) -> Animation? {
        dict[index]
    }

    public init(textureMap: TextureMap) throws {
        self.name = textureMap.meta.image ?? "texturemap"
        var dict: [String: Animation] = [:]
        if let frameTags = textureMap.meta.frameTags {
            for frameTag in frameTags {
                let startIndex = frameTag.from
                let endIndex = frameTag.to
                let frames = textureMap.frames[(startIndex...endIndex)].map { frame in
                    Animation.Frame(name: frame.filename, duration: frame.duration)
                }
                dict[frameTag.name] = Animation(name: frameTag.name, frames: frames)
            }
        }
        self.dict = dict
    }
}
