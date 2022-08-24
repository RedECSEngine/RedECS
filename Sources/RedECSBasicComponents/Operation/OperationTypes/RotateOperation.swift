import RedECS
import Geometry

public struct RotateOperation: Operation {
    public typealias Action = Int
    
    public enum Strategy: Equatable, Codable {
        case by(Double) // degrees
        case to(Double)
    }
    
    public var strategy: Strategy
    public var duration: Double
    public var currentTime: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(
        strategy: Strategy,
        duration: Double,
        currentTime: Double = 0
    ) {
        self.strategy = strategy
        self.duration = duration
        self.currentTime = currentTime
    }
    
    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Action> {
        switch strategy {
        case .by(let amount):
            let percentage = delta / duration
            let rotateByIncrement = amount * percentage
            state.transform[id]?.rotate += rotateByIncrement
        case .to(_):
            fatalError("not implemented yet")
            break
        }
        currentTime += delta
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
