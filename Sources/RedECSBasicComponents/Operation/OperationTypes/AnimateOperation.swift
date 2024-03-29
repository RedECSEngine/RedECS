import RedECS

public struct AnimateOperation: Operation {
    public struct FrameData: Equatable, Codable {
        public var texture: TextureReference
        public var duration: Double
        
        public init(texture: TextureReference, duration: Double) {
            self.texture = texture
            self.duration = duration
        }
    }
    
    public var currentTime: Double = 0
    public var currentFrameTime: Double = 0
    public var currentFrameIndex: Int = 0
    public var frames: [FrameData]
    public var isComplete: Bool = false
    public var duration: Double {
        frames.reduce(0) { $0 + $1.duration }
    }
    
    public init(
        frames: [FrameData]
    ) {
        self.frames = frames
    }
        
    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Int> {
        guard !isComplete, !frames.isEmpty else {
            isComplete = true
            return .none
        }
        
        if currentTime == 0 {
            state.sprite[id]?.setTexture(frames[0].texture)
            currentTime += delta
            return .none // first frame doesnt need frame delta applied on first tick
        }
        
        currentTime += delta
        currentFrameTime += delta
        
        guard currentFrameTime > frames[currentFrameIndex].duration else {
            return .none
        }
        
        currentFrameTime = 0
        currentFrameIndex += 1
        let isPastFinalFrame = (currentFrameIndex >= frames.count)
        if isPastFinalFrame {
            isComplete = true
            return .none
        }
         
        state.sprite[id]?.setTexture(frames[currentFrameIndex].texture)
        
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
        currentFrameTime = 0
        currentFrameIndex = 0
        isComplete = false
    }
}

public extension SpriteAnimationDictionary {
    func operation(for name: String) -> AnimateOperation? {
        guard let anim = self.dict[name] else { return nil }
        let frames = anim.frames.map {
            AnimateOperation.FrameData(
                texture: .init(textureId: self.name, frameId: $0.name),
                duration: $0.duration / 1000
            )
        }
        return AnimateOperation(frames: frames)
    }
}
