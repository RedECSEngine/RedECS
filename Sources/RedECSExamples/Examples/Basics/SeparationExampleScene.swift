import Foundation
import RedECS
import SpriteKit
import RedECSBasicComponents
import RedECSRenderingComponents
import RedECSSpriteKitSupport
import Geometry

extension NSImage {
    func tint(color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()

        color.set()

        let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
        imageRect.fill(using: .sourceAtop)

        image.unlockFocus()

        return image
    }
}

public struct SeparationExampleState: GameState {
    public var entities: EntityRepository = .init()
    public var sprite: [EntityId: SpriteComponent] = [:]
    public var transform: [EntityId: TransformComponent] = [:]
    public var movement: [EntityId: MovementComponent] = [:]
    public var separation: [EntityId: SeparationComponent] = [:]
    
    public init() {}
}


extension SeparationExampleState {
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

extension SeparationExampleState {
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

extension SeparationExampleState {
    var spriteRenderingContext: SpriteRenderingContext {
        get {
            return SpriteRenderingContext(
                entities: entities,
                position: position,
                transform: .init(),
                sprite: sprite
            )
        }
        set {
            self.position = newValue.position
            self.sprite = newValue.sprite
        }
    }
}

public class SeparationExampleScene: SKScene {
    
    var store: GameStore<AnyReducer<SeparationExampleState, Never, ExampleGameEnvironment>>!
    
    public override init() {
        super.init(size: .init(width: 640, height: 480))
        store = GameStore(
            state: SeparationExampleState(),
            environment: ExampleGameEnvironment(renderer: .init(scene: self)),
            reducer: (
                SpriteKitSpriteRenderingReducer()
                    .pullback(toLocalState: \.spriteRenderingContext, toLocalEnvironment: { $0 as SpriteKitRenderingEnvironment })
                    + MovementReducer()
                    .pullback(toLocalState: \.movementContext)
                    + SeparationReducer()
                    .pullback(toLocalState: \.separationContext)
            )
                .eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.position),
                .init(keyPath: \.movement),
                .init(keyPath: \.sprite),
                .init(keyPath: \.separation)
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
extension SeparationExampleScene {

    public override func mouseDown(with event: NSEvent) {
        
    }
    
    public override func mouseDragged(with event: NSEvent) {
        let entity = UUID().uuidString
        store.sendSystemAction(.addEntity(entity, []))
        
        let sprite = SpriteComponent(entity: entity)
        if #available(macOS 11.0, *) {
            let image = NSImage(
                systemSymbolName: "arrow.up.circle.fill",
                accessibilityDescription: nil)?
                .tint(color: .init(
                        red: .random(in: 0...1),
                        green: .random(in: 0...1),
                        blue: .random(in: 0...1), alpha: 1
                ))
            let texture = SKTexture(image: image ?? NSImage())
//            sprite.node.texture = texture
//            sprite.node.size = .init(width: 60, height: 60)
        }
        store.sendSystemAction(
            .addComponent(
                sprite,
                into: \.sprite
            )
        )
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
                MovementComponent(entity: entity, velocity: .zero, travelSpeed: 1),
                into: \.movement
            )
        )
        store.sendSystemAction(
            .addComponent(
                SeparationComponent(entity: entity, radius: 80),
                into: \.separation
            )
        )
    }
    
    public override func mouseUp(with event: NSEvent) {
        
    }

}
#endif
