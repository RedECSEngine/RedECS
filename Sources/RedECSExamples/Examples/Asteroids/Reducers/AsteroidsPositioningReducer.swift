import Foundation
import SpriteKit
import RedECS
import RedECSBasicComponents
import RedECSRenderingComponents
import Geometry

// repositions ships and asteroids, and removes bullets
public struct AsteroidsPositioningReducer: Reducer {
    public func reduce(
        state: inout AsteroidsGameState,
        delta: Double,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
        
        var gameEffects: [GameEffect<AsteroidsGameState, AsteroidsGameAction>] = []
        
        for entity in state.entities.values {
            guard var position = state.position[entity.id] else { continue }
            var shouldRemove = false
            if position.point.x > 480 {
                if entity.tags.contains("bullet") {
                    shouldRemove = true
                } else {
                    position.point.x = 0
                }
            }
            if position.point.x < 0 {
                if entity.tags.contains("bullet") {
                    shouldRemove = true
                } else {
                    position.point.x = 480
                }
            }
            if position.point.y > 480 {
                if entity.tags.contains("bullet") {
                    shouldRemove = true
                } else {
                    position.point.y = 0
                }
            }
            if position.point.y < 0 {
                if entity.tags.contains("bullet") {
                   shouldRemove = true
                } else {
                    position.point.y = 480
                }
            }
            
            if !shouldRemove && entity.tags.contains("bullet") {
                for (asteroidId, asteroid) in state.asteroid {
                    guard let asteroidPosition = state.position[asteroidId] else { continue }
                    if asteroid.intersects(Circle(center: position.point, radius: 2), whenPositionedAt: asteroidPosition.point) {
                        gameEffects.append(.system(.removeEntity(asteroidId)))
                        if asteroid.size > 1 {
                            gameEffects.append(.many([
                                generateAsteroidCreationActions(size: asteroid.size - 1, point: asteroidPosition.point),
                                generateAsteroidCreationActions(size: asteroid.size - 1, point: asteroidPosition.point),
                                generateAsteroidCreationActions(size: asteroid.size - 1, point: asteroidPosition.point)
                            ]))
                        }
                        shouldRemove = true
                    }
                }
            }
            
            if shouldRemove {
                gameEffects.append(.system(.removeEntity(entity.id)))
            } else {
                state.position[entity.id] = position
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
