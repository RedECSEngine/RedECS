import RedECS

// TODO: Implement these:
// Follow Path
// speed increase/decrease

public protocol Operation: Codable & Equatable {
    associatedtype Action: Equatable & Codable
    
    var currentTime: Double { get }
    var duration: Double { get }
    var isComplete: Bool { get }
    
    mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Action>
    
    mutating func reset()
}

public extension Operation {
    static var InstantDuration: Double { 0 }
    static var InfiniteDuration: Double { -1 }
}
