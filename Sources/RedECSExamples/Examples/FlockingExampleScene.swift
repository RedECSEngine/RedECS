import Foundation
import RedECS
import SpriteKit
import RedECSBasicComponents

public class FlockingExampleScene: SKScene {
    
    var store: GameStore<AnyReducer<ExampleGameState, Never, ExampleGameEnvironment>>!
    
    public override init() {
        super.init(size: .init(width: 640, height: 480))
        store = GameStore(
            state: ExampleGameState(),
            environment: ExampleGameEnvironment(renderer: self),
            reducer: (
                ShapeRenderingReducer()
                    + MovementReducer()
                    .pullback(toLocalState: \.movementContext)
                + FlockingReducer()
                    .pullback(toLocalState: \.flockingContext)
            )
                .eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.position),
                .init(keyPath: \.movement),
                .init(keyPath: \.shape),
                .init(keyPath: \.flocking)
            ]
        )
        
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) { nil }
    
    var lastTime: TimeInterval?
    
    public override func update(_ currentTime: TimeInterval) {
        
        if let lastTime = lastTime {
            store.sendDelta((currentTime - lastTime) * 100)
        }
        lastTime = currentTime
    }
    
}

#if os(OSX)
// Mouse-based event handling
extension FlockingExampleScene {

    public override func mouseDown(with event: NSEvent) {
        
    }
    
    public override func mouseDragged(with event: NSEvent) {
        let entity = UUID().uuidString
        store.sendSystemAction(.addEntity(entity))
        store.sendSystemAction(
            .addComponent(
                ShapeComponent(entity: entity, radius: 30),
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
    }
    
    public override func mouseUp(with event: NSEvent) {
        
    }

}
#endif
