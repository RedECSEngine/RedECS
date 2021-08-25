import Foundation

public protocol GameComponent: Codable, Equatable {
    var entity: EntityId { get }
    
    func prepareForDestruction()
}

public extension GameComponent {
    func prepareForDestruction() { }
}
