import RedECS
import Geometry

public struct MoveOperation: Operation {
    public typealias Action = Int
    
    public enum Strategy: Equatable, Codable {
        case by(Point)
        case to(Point)
    }
    
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
            case .by(let amount):
                self.amount = amount
            case .to(let location):
                let currentPos = (state.transform[id]?.position ?? .zero)
                self.amount = location.diffOf(currentPos)
            }
        }
        
        let percentage = delta / duration
        let moveByIncrement = amount * percentage
        state.transform[id]?.position += moveByIncrement
        currentTime += delta
        
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
