import Foundation
import RedECS
import SpriteKit
import RedECSBasicComponents
import RedECSRenderingComponents

public struct ExampleGameState: GameState {
    public var entities: EntityRepository = .init()
    public var shape: [EntityId: ShapeComponent] = [:]
    public var position: [EntityId: PositionComponent] = [:]
    public var transform: [EntityId: TransformComponent] = [:]
    public var movement: [EntityId: MovementComponent] = [:]
    public var pathing: [EntityId: PathingComponent] = [:]
    public var separation: [EntityId: SeparationComponent] = [:]
    public var following: [EntityId: FollowEntityComponent] = [:]
    
    public var flocking: [EntityId: FlockingComponent] = [:]
    
    public init() {}
}

extension ExampleGameState {
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

extension ExampleGameState {
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

extension ExampleGameState {
    var separationContext: SeparationReducerContext {
        get {
            SeparationReducerContext(
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
            FollowEntityReducerContext(
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
            PathingReducerContext(
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
