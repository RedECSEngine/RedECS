import Foundation
import RedECS
import SpriteKit
import RedECSBasicComponents

public struct ExampleGameEnvironment {
    public init(renderer: SKScene) {
        self.renderer = renderer
    }
    
    public var renderer: SKScene
}

public struct ExampleGameState: GameState {
    public var entities: Set<EntityId> = []
    public var shape: [EntityId: ShapeComponent] = [:]
    public var position: [EntityId: PositionComponent] = [:]
    public var movement: [EntityId: MovementComponent] = [:]
    public var pathing: [EntityId: PathingComponent] = [:]
    public var separation: [EntityId: SeparationComponent] = [:]
    public var following: [EntityId: FollowEntityComponent] = [:]
    
    public var flocking: [EntityId: FlockingComponent] = [:]
    
    public init() {}
}

extension ExampleGameState {
    var movementContext: MovementReducerContext {
        get {
            return MovementReducerContext(entities: entities, position: position, movement: movement)
        }
        set {
            self.position = newValue.position
            self.movement = newValue.movement
        }
    }
}

extension ExampleGameState {
    var separationContext: SeparationReducerContext {
        get {
            return SeparationReducerContext(
                entities: entities,
                positions: position,
                movement: movement,
                separation: separation
            )
        }
        set {
            self.position = newValue.positions
            self.movement = newValue.movement
            self.separation = newValue.separation
        }
    }
}

extension ExampleGameState {
    var followingContext: FollowEntityReducerContext {
        get {
            return FollowEntityReducerContext(
                entities: entities,
                position: position,
                movement: movement,
                followEntity: self.following
            )
        }
        set {
            self.position = newValue.position
            self.movement = newValue.movement
            self.following = newValue.followEntity
        }
    }
}

extension ExampleGameState {
    var pathingContext: PathingReducerContext {
        get {
            return PathingReducerContext(
                entities: entities,
                position: position,
                movement: movement,
                pathing: pathing
            )
        }
        set {
            self.position = newValue.position
            self.movement = newValue.movement
            self.pathing = newValue.pathing
        }
    }
}

extension ExampleGameState {
    var flockingContext: FlockingReducerContext {
        get {
            FlockingReducerContext(
                entities: entities,
                position: position,
                movement: movement,
                flocking: flocking,
                follow: following
            )
        }
        set {
            self.position = newValue.position
            self.movement = newValue.movement
            self.flocking = newValue.flocking
            self.following = newValue.follow
        }
    }
}
