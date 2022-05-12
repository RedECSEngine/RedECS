import RedECS
import Geometry

public struct PathingReducerContext: GameState {
    public var entities: EntityRepository = .init()
    public var position: [EntityId: PositionComponent]
    public var movement: [EntityId: MovementComponent]
    public var pathing: [EntityId: PathingComponent]
    
    public init(
        entities: EntityRepository = .init(),
        position: [EntityId : PositionComponent],
        movement: [EntityId : MovementComponent],
        pathing: [EntityId : PathingComponent]
    ) {
        self.entities = entities
        self.position = position
        self.movement = movement
        self.pathing = pathing
    }
}

public enum PathingAction: Equatable {
    case setPath(EntityId, [Point])
    case appendPath(EntityId, Point)
    case requestPathingCalculation(EntityId, to: Point)
    case pathingComplete(EntityId)
}

public struct PathingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout PathingReducerContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<PathingReducerContext, PathingAction> {
        var effects: [GameEffect<PathingReducerContext, PathingAction>] = []
        state.pathing.forEach { (id, pathing) in
            guard let firstLocation = pathing.travelPath.first,
                  let position = state.position[id] else { return }
            
            if position.point.distanceFrom(firstLocation) < pathing.allowableProximityVariance {
                state.pathing[id]?.travelPath.removeFirst()
                if state.pathing[id]?.travelPath.isEmpty == true {
                    effects.append(.game(.pathingComplete(id)))
                }
            } else {
                var velocity: Point = .zero
                let diffPos = position.point.diffOf(firstLocation)
                let maxDirectionalDistance = max(abs(diffPos.x), abs(diffPos.y))

                velocity.x -= diffPos.x != 0 ? max(min(diffPos.x / maxDirectionalDistance, 1) , -1) : 0
                velocity.y -= diffPos.y != 0 ? max(min(diffPos.y / maxDirectionalDistance, 1) , -1) : 0

                state.movement[id]?.velocity = velocity
            }
        }
        guard !effects.isEmpty else { return .none }
        return .many(effects)
    }
    
    public func reduce(
        state: inout PathingReducerContext,
        action: PathingAction,
        environment: ()
    ) -> GameEffect<PathingReducerContext, PathingAction> {
        switch action {
        case .setPath(let entity, let points):
            assert(state.pathing[entity] != nil, "attempting to use pathing on an entity without a pathing component")
            state.pathing[entity]?.travelPath = points
        case .appendPath(let entity, let point):
            assert(state.pathing[entity] != nil, "attempting to use pathing on an entity without a pathing component")
            state.pathing[entity]?.travelPath.append(point)
        case .requestPathingCalculation(let entity, _):
            assert(state.pathing[entity] != nil, "attempting to use pathing on an entity without a pathing component")
            break // Needs implementing by another custom reducer
        case .pathingComplete:
            break
        }
        return .none
    }
}

public struct StraightLinePathingCalculatorReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout PathingReducerContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<PathingReducerContext, PathingAction> {
        return .none
    }
    
    public func reduce(
        state: inout PathingReducerContext,
        action: PathingAction,
        environment: ()
    ) -> GameEffect<PathingReducerContext, PathingAction> {
        switch action {
        case .requestPathingCalculation(let eId, let point):
            return .game(.setPath(eId, [point]))
        default:
            break
        }
        return .none
    }
}
