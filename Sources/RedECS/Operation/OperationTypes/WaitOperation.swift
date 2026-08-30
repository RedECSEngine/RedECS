
public struct WaitOperation: Operation {
    public var duration: Double
    public var currentTime: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(duration: Double) {
        self.duration = duration
    }
    
    public mutating func run<State: BasicOperationCapableState>(
        id: EntityId,
        state: inout State,
        delta: Double
    ) -> GameEffect<State, Int> {
        currentTime += delta
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
