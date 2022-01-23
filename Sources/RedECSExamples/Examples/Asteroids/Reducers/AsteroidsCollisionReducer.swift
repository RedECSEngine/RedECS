import Foundation
import SpriteKit
import RedECS
import RedECSBasicComponents
import RedECSRenderingComponents
import Geometry

public struct AsteroidsCollisionReducer: Reducer {
    public func reduce(
        state: inout AsteroidsGameState,
        delta: Double,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
        
        var gameEffects: [GameEffect<AsteroidsGameState, AsteroidsGameAction>] = []
        
        var bullets: [EntityId] = []
        var asteroids: [EntityId] = []
        
        for entity in state.entities.values {
            if entity.tags.contains("bullet") {
                bullets.append(entity.id)
            }
            if entity.tags.contains("asteroid") {
                asteroids.append(entity.id)
            }
        }
        
        bullets.forEach { bulletId in
            guard let shape = state.shape[bulletId],
                  case let .circle(circle) = shape.shape else { return }
            
            circle.intersects(circle)
            
            asteroids.forEach { asteroidId in
                
            }
        }
        
        return .many(gameEffects)
    }
    
    public func reduce(
        state: inout AsteroidsGameState,
        action: AsteroidsGameAction,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
        return .none
    }
    
}
