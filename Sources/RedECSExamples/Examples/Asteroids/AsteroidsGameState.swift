import Foundation
import RedECS
import RedECSBasicComponents
import RedECSRenderingComponents

public struct AsteroidsGameState: GameState {
    public var entities: EntityRepository = .init()
    
    public var asteroid: [EntityId: AsteroidComponent] = [:]
    public var ship: [EntityId: ShipComponent] = [:]
    public var shape: [EntityId: ShapeComponent] = [:]
    public var position: [EntityId: PositionComponent] = [:]
    public var transform: [EntityId: TransformComponent] = [:]
    public var movement: [EntityId: MovementComponent] = [:]
    public var momentum: [EntityId: MomentumComponent] = [:]
    
    public var keyboardInput: [EntityId: KeyboardInputComponent] = [:]
     
    /**
        
    - collision (proximity interaction)
    - asteroid positioning safely away from ship
    - asteroid explode on collision
     */
    
    public init() {}
}

extension AsteroidsGameState {
    var shapeContext: ShapeReducerContext {
        get {
            ShapeReducerContext(
                entities: entities,
                position: position,
                transform: transform,
                shape: shape
            )
        }
        set {
            self.position = newValue.position
            self.transform = newValue.transform
            self.shape = newValue.shape
        }
    }
}

extension AsteroidsGameState {
    var movementContext: MovementReducerContext {
        get {
            MovementReducerContext(
                entities: entities,
                position: position,
                movement: movement
            )
        }
        set {
            self.position = newValue.position
            self.movement = newValue.movement
        }
    }
}

extension AsteroidsGameState {
    var momentumContext: MomentumReducerContext {
        get {
            MomentumReducerContext(
                entities: entities,
                momentum: momentum,
                movement: movement
            )
        }
        set {
            self.momentum = newValue.momentum
            self.movement = newValue.movement
        }
    }
}

extension AsteroidsGameState {
    var keyboardInputContext: KeyboardInputReducerContext {
        get {
            KeyboardInputReducerContext(entities: entities, keyboardInput: keyboardInput)
        }
        set {
            self.keyboardInput = newValue.keyboardInput
        }
    }
}
