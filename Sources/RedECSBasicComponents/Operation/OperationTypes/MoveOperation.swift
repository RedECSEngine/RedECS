import RedECS
import Geometry

public struct MoveOperation: Operation {
    public typealias Action = Int
    
    public enum Strategy: Equatable, Codable {
        case by(Point)
        case to(Point)
    }
    
    public var strategy: Strategy
    public var duration: Double
    public var currentTime: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(strategy: Strategy, duration: Double, currentTime: Double = 0) {
        self.strategy = strategy
        self.duration = duration
        self.currentTime = currentTime
    }
    
    public mutating func run(id: EntityId, state: inout BasicOperationComponentContext, delta: Double) -> GameEffect<BasicOperationComponentContext, Action> {
        switch strategy {
        case .by(let point):
            let percentage = delta / duration
            let moveByIncrement = point * percentage
            state.transform[id]?.position += moveByIncrement
            currentTime += delta
        case .to(_):
            fatalError("not implemented yet")
        }
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
