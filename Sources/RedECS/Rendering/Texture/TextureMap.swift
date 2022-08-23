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
        public var filename: String
        public var frame: TextureRect
        public var rotated: Bool
        public var trimmed: Bool
        public var spriteSourceSize: TextureRect
        public var sourceSize: TextureSize
        public var duration: Double?
    }
    
    public struct Metadata: Codable {
        public var image: String?
        public var size: TextureSize
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
