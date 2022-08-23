public protocol GameComponent: Codable, Equatable {
    var entity: EntityId { get }
}
