import RedECS

// TODO: Implement these:
// Repeat Count
// Scale
// Rotate
// Show/Hide
// Animate
// Follow Path

public protocol Operation: Codable & Equatable {
    associatedtype Action: Equatable & Codable
    
    var currentTime: Double { get }
    var isComplete: Bool { get }
    
    mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Action>
    
    mutating func reset()
}
