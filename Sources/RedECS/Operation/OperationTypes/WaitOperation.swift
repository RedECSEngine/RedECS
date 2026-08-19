
public struct WaitOperation: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.wait" }

    public var duration: Double
    public var currentTime: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(duration: Double) {
        self.duration = duration
    }
    
    public mutating func run(delta: Double) {
        currentTime += delta
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
