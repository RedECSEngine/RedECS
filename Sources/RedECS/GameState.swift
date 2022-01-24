import Foundation

public protocol GameState: Codable, Equatable {
    var entities: EntityRepository { get set }
}
