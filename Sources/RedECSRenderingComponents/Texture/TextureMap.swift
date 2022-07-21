public struct TextureMap: Codable {
    public struct TextureRect: Codable {
        public let x: Double
        public let y: Double
        public let w: Double
        public let h: Double
    }
    
    public struct TextureSize: Codable {
        public let w: Double
        public let h: Double
    }
    
    public struct Frame: Codable {
        var filename: String
        var frame: TextureRect
        var rotated: Bool
        var trimmed: Bool
        var spriteSourceSize: TextureRect
        var sourceSize: TextureSize
        var duration: Double
    }
    
    public struct Metadata: Codable {
        public var image: String?
        public var size: TextureRect
        public var format: String?
        public var frameTags: [FrameTag]?
    }
    
    public struct FrameTag: Codable {
        public var name: String
        public var from: Int
        public var to: Int
        public var direction: String
    }
    
    public var frames: [Frame]
    public var meta: Metadata
}
