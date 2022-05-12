import Foundation
import RedECS
import SpriteKit
import RedECSBasicComponents
import RedECSRenderingComponents
import RedECSSpriteKitSupport
import Geometry

public class FollowFlockingPathingExampleScene: SKScene {
    
    var store: GameStore<AnyReducer<ExampleGameState, PathingAction, ExampleGameEnvironment>>!
    
    public override init() {
        super.init(size: .init(width: 640, height: 480))
        
        var reducers: AnyReducer<ExampleGameState, PathingAction, ExampleGameEnvironment> = (
            SpriteKitShapeRenderingReducer()
                .pullback(toLocalState: \.shapeContext, toLocalEnvironment: { $0 as SpriteKitRenderingEnvironment })
                + MovementReducer()
                .pullback(toLocalState: \.movementContext)
                + FlockingReducer()
                .pullback(toLocalState: \.flockingContext)
        )
        .eraseToAnyReducer()
        reducers = (
            reducers
                + FollowEntityReducer()
                .pullback(toLocalState: \.followingContext)
                + PathingReducer()
                .pullback(toLocalState: \.pathingContext)
        )
        .eraseToAnyReducer()
        
        store = GameStore(
            state: ExampleGameState(),
            environment: ExampleGameEnvironment(renderer: .init(scene: self)),
            reducer: reducers,
            registeredComponentTypes: [
                .init(keyPath: \.position),
                .init(keyPath: \.movement),
                .init(keyPath: \.shape),
                .init(keyPath: \.flocking),
                .init(keyPath: \.following),
                .init(keyPath: \.pathing)
            ]
        )
        
        createPlayer()
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) { nil }
    
    var lastTime: TimeInterval?
    var playerId = UUID().uuidString
    
    public override func update(_ currentTime: TimeInterval) {
        if let lastTime = lastTime {
            store.sendDelta((currentTime - lastTime) * 100)
        }
        lastTime = currentTime
    }
    
    public func createPlayer() {
        store.sendSystemAction(.addEntity(playerId, []))
        
        let playerShape = ShapeComponent(entity: playerId, shape: .circle(Circle(radius: 30)))
        
        store.sendSystemAction(
            .addComponent(
                playerShape,
                into: \.shape
            )
        )
        store.sendSystemAction(
            .addComponent(
                PositionComponent(
                    entity: playerId,
                    point: Point(
                        x: 320,
                        y: 240
                    )
                ),
                into: \.position
            )
        )
        store.sendSystemAction(
            .addComponent(
                MovementComponent(entity: playerId, velocity: .zero, travelSpeed: 1),
                into: \.movement
            )
        )
        store.sendSystemAction(
            .addComponent(
                PathingComponent(entity: playerId),
                into: \.pathing
            )
        )
    }
    
}

#if os(OSX)
// Mouse-based event handling
extension FollowFlockingPathingExampleScene {

    public override func mouseDown(with event: NSEvent) {
        let point = event.location(in: self)
        
        store.sendAction(
            .appendPath(playerId, Point(x: Double(point.x), y: Double(point.y)))
        )
    }
    
    public override func mouseDragged(with event: NSEvent) {
        
        guard store.state.entities.entityIds.count < 15 else { return }
        
        let entity = UUID().uuidString
        store.sendSystemAction(.addEntity(entity, []))
        store.sendSystemAction(
            .addComponent(
                ShapeComponent(
                    entity: entity,
                    shape:  .circle(Circle(radius: 20))
                ),
                into: \.shape
            )
        )
        store.sendSystemAction(
            .addComponent(
                PositionComponent(
                    entity: entity,
                    point: Point(
                        x: Double(event.location(in: self).x),
                        y: Double(event.location(in: self).y)
                    )
                ),
                into: \.position
            )
        )
        store.sendSystemAction(
            .addComponent(
                MovementComponent(entity: entity, velocity: .zero, travelSpeed: 1),
                into: \.movement
            )
        )
        store.sendSystemAction(
            .addComponent(
                FlockingComponent(entity: entity),
                into: \.flocking
            )
        )
        store.sendSystemAction(
            .addComponent(
                FollowEntityComponent.init(entity: entity, leaderId: playerId, maxDistance: 150),
                into: \.following
            )
        )
    }
    
    public override func mouseUp(with event: NSEvent) {
        
    }

}
#endif
