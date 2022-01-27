import Foundation
import RedECS
import Geometry

public struct FlockingComponent: GameComponent {
    public var entity: EntityId
    
    public var separationRadius: Double
    public var separationWeight: Double
    
    public var alignmentRadius: Double
    public var alignmentWeight: Double
    
    public var cohesionRadius: Double
    public var cohesionWeight: Double
    
    public init(
        entity: EntityId,
        separationRadius: Double = 80,
        separationWeight: Double = 2,
        alignmentRadius: Double = 80,
        alignmentWeight: Double = 1,
        cohesionRadius: Double = 80,
        cohesionWeight: Double = 1
    ) {
        self.entity = entity
        self.separationRadius = separationRadius
        self.separationWeight = separationWeight
        self.alignmentRadius = alignmentRadius
        self.alignmentWeight = alignmentWeight
        self.cohesionRadius = cohesionRadius
        self.cohesionWeight = cohesionWeight
    }
}

public struct FlockingReducerContext: GameState {
    public var entities: EntityRepository = .init()
    
    public var position: [EntityId: PositionComponent]
    public var movement: [EntityId: MovementComponent]
    public var flocking: [EntityId: FlockingComponent]
    public var follow: [EntityId: FollowEntityComponent]
    
    public init(
        entities: EntityRepository = .init(),
        position: [EntityId : PositionComponent],
        movement: [EntityId : MovementComponent],
        flocking: [EntityId : FlockingComponent],
        follow: [EntityId: FollowEntityComponent]
    ) {
        self.entities = entities
        self.position = position
        self.movement = movement
        self.flocking = flocking
        self.follow = follow
    }
}

public struct FlockingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout FlockingReducerContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<FlockingReducerContext, Never> {
        state.flocking.forEach { (id, flocking) in
            guard let position = state.position[id] else { return }
            let follow = state.follow[id]
            
            var alignment: Point = .zero
            var cohesion: Point = .zero
            var separation: Point = .zero
            var neighborCount: Int32 = 0
            
            state.flocking.forEach { (otherEntityId, _) in
                guard id != otherEntityId,
                      let otherPosition = state.position[otherEntityId],
                      let otherMovement = state.movement[otherEntityId] else { return }
                
                let distance = position.point.distanceFrom(otherPosition.point)
                guard distance <= flocking.separationRadius
//                        || (otherEntityId == follow?.leaderId && distance > (follow?.maxDistance ?? .greatestFiniteMagnitude))
                else {
                    return
                }
                
                alignment += otherMovement.velocity
                cohesion += otherPosition.point
                separation += (otherPosition.point - position.point)
                neighborCount += 1
            }
            
            guard neighborCount > 0 else {
                return
            }

            alignment /= Double(neighborCount)
            
            cohesion /= Double(neighborCount)
            cohesion -= position.point
            
            separation /= Double(neighborCount)
            separation *= -1
            
            alignment.normalize(to: flocking.alignmentWeight)
            cohesion.normalize(to: flocking.cohesionWeight)
            separation.normalize(to: flocking.separationWeight)
            
            state.movement[id]?.velocity =
                alignment +
                cohesion +
                separation
        }
        return .none
    }
}
