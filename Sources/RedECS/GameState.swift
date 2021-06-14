import Foundation

public typealias EntityId = String

public protocol GameState: Codable, Equatable {
    var entities: Set<EntityId> { get set }
}
