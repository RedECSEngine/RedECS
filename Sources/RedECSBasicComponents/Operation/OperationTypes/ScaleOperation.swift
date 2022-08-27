import RedECS
import Geometry

public struct ScaleOperation: Operation {
    public enum Strategy: Equatable, Codable {
        case by(Point)
        case to(Point)
    }
    
    public typealias Action = Int
    
    public var strategy: Strategy
    public var amount: Point = .zero
    public var duration: Double
    public var currentTime: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(strategy: Strategy, duration: Double, currentTime: Double = 0) {
        self.strategy = strategy
        self.duration = duration
        self.currentTime = currentTime
    }
    
    public mutating func run(id: EntityId, state: inout BasicOperationComponentContext, delta: Double) -> GameEffect<BasicOperationComponentContext, Action> {
        
        if currentTime == 0 {
            switch strategy {
            case .by(let point):
                self.amount = point
            case .to(let point):
                let scale = state.transform[id]?.scale ?? .zero
                self.amount = point - scale
            }
        }
        
        let percentage = delta / duration
        let scaleIncrement = amount * percentage
        state.transform[id]?.scale += scaleIncrement
        currentTime += delta
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
