import RedECS
import Geometry

public struct ScaleOperation: Operation {
    enum Strategy {
        case by(Point)
        case to(Point)
    }
    
    public typealias Action = Int
    
    public var moveBy: Point
    public var duration: Double
    public var currentTime: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(moveBy: Point, duration: Double, currentTime: Double = 0) {
        self.moveBy = moveBy
        self.duration = duration
        self.currentTime = currentTime
    }
    
    public mutating func run(id: EntityId, state: inout BasicOperationComponentContext, delta: Double) -> GameEffect<BasicOperationComponentContext, Action> {
        let percentage = delta / duration
        let moveByIncrement = moveBy * percentage
        state.transform[id]?.position += moveByIncrement
        currentTime += delta
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
