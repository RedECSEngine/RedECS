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
        
        for entityId in state.entities.entityIds {
            guard let entity = state.entities[entityId],
                    var position = state.position[entityId] else { continue }
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
                        
            if shouldRemove {
                gameEffects.append(.system(.removeEntity(entityId)))
            } else {
                state.position[entityId] = position
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
