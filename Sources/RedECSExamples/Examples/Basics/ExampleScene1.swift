import Foundation
import RedECS
import SpriteKit
import RedECSBasicComponents
import RedECSRenderingComponents
import RedECSSpriteKitSupport
import Geometry

public class ExampleScene1: SKScene {
    
    var store: GameStore<AnyReducer<ExampleGameState, Never, ExampleGameEnvironment>>!
    
    public override init() {
        super.init(size: .init(width: 640, height: 480))
        store = GameStore(
            state: ExampleGameState(),
            environment: ExampleGameEnvironment(renderer: .init(scene: self)),
            reducer: (
                SpriteKitShapeRenderingReducer()
                    .pullback(toLocalState: \.shapeContext, toLocalEnvironment: { $0 as ExampleGameEnvironment })
                + MovementReducer()
                    .pullback(toLocalState: \.movementContext)
            )
                .eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.position),
                .init(keyPath: \.movement),
                .init(keyPath: \.shape)
            ]
        )
        
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) { nil }
    
    var lastTime: TimeInterval?
    
    public override func update(_ currentTime: TimeInterval) {
        
        if let lastTime = lastTime {
            store.sendDelta(currentTime - lastTime)
        }
        lastTime = currentTime
    }
    
}

#if os(OSX)
// Mouse-based event handling
extension ExampleScene1 {

    public override func mouseDown(with event: NSEvent) {
        
    }
    
    public override func mouseDragged(with event: NSEvent) {
        let entity = UUID().uuidString
        store.sendSystemAction(.addEntity(entity, []))
        store.sendSystemAction(.addComponent(ShapeComponent(entity: entity, shape: .circle(Circle(radius: 8))), into: \.shape))
        store.sendSystemAction(
            .addComponent(
                TransformComponent(
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
                MovementComponent(
                    entity: entity,
                    velocity: Point(
                        x: Double.random(in: -200...200),
                        y: Double.random(in: -200...200)
                    ),
                    travelSpeed: 1
                ),
                into: \.movement
            )
        )
    }
    
    public override func mouseUp(with event: NSEvent) {
        
    }

}
#endif
