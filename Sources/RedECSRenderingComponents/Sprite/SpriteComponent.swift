import Foundation
import SpriteKit
import RedECS

public struct SpriteComponent: GameComponent {
    enum CodingKeys: String, CodingKey {
        case entity
    }
    
    public var entity: EntityId
    public var node: SKSpriteNode = .init()
    
    public init(
        entity: EntityId
    ) {
        self.entity = entity
    }
    
    public func prepareForDestruction() {
        node.removeFromParent()
    }
}
