import RedECS

public struct SpriteComponent: GameComponent {
    enum CodingKeys: String, CodingKey {
        case entity
    }
    
    public var entity: EntityId
    
    public init(
        entity: EntityId
    ) {
        self.entity = entity
    }
}
