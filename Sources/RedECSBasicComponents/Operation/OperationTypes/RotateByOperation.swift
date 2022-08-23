import RedECS
import Geometry

public struct RotateByOperation: Operation {
    public typealias Action = Int
    
    public var rotateBy: Double // degrees
    public var duration: Double
    public var currentTime: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(rotateBy: Double, duration: Double, currentTime: Double = 0) {
        self.rotateBy = rotateBy
        self.duration = duration
        self.currentTime = currentTime
    }
    
    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Action> {
        let percentage = delta / duration
        let rotateByIncrement = rotateBy * percentage
        state.transform[id]?.rotate += rotateByIncrement
        currentTime += delta
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
