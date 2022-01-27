import Foundation
import RedECS
import Geometry

public struct SeparationReducerContext: GameState {
    public var entities: EntityRepository = .init()
    public var positions: [EntityId: PositionComponent]
    public var movement: [EntityId: MovementComponent]
    public var separation: [EntityId: SeparationComponent]
    public init(
        entities: EntityRepository = .init(),
        positions: [EntityId: PositionComponent],
        movement: [EntityId: MovementComponent],
        separation: [EntityId: SeparationComponent]
    ) {
        self.entities = entities
        self.positions = positions
        self.movement = movement
        self.separation = separation
    }
}

public struct SeparationReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout SeparationReducerContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<SeparationReducerContext, Never> {
        state.separation.forEach { (id, separation) in
            guard let position = state.positions[id] else { return }
            
            var velocity: Point = .zero
            var neighborCount: Int32 = 0
            
            state.positions.forEach { (otherEntityId, otherPosition) in
                guard id != otherEntityId else { return }
                
                var distance = position.point.distanceFrom(otherPosition.point)
                
                guard distance <= separation.radius else {
                    return
                }
                
                if distance < 0.01 {
                    distance = 0.01
                }
                
                let headingVector = position.point.diffOf(otherPosition.point)
                let scale = 1 - (distance / separation.radius)
                let relativeHeadingVector = headingVector / distance
                let finalHeadingVector = relativeHeadingVector / scale
                
                velocity.x += finalHeadingVector.x
                velocity.y += finalHeadingVector.y
                neighborCount += 1
            }
            
            guard neighborCount > 0 else {
                state.movement[id]?.velocity = .zero
                return
            }

            let finalX = max(-1, min(1, velocity.x))
            let finalY = max(-1, min(1, velocity.y))
            let adjustmentVector = Point(x: finalX, y: finalY)
            state.movement[id]?.velocity = adjustmentVector
        }
        return .none
    }
}
