import Foundation
import SpriteKit
import RedECS
import RedECSBasicComponents
import RedECSRenderingComponents
import Geometry

public enum AsteroidsGameAction: Equatable {
    case newGame
    case keyboardInput(KeyboardInputAction)
}

public struct AsteroidsGameReducer: Reducer {
    public func reduce(
        state: inout AsteroidsGameState,
        delta: Double,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
        
        guard let ship = state.ship["ship"],
           var position = state.position[ship.entity],
           var momentum = state.momentum[ship.entity],
           var transform = state.transform[ship.entity] else {
            fatalError("dafuk!?")
        }
        
        var gameEffects: [GameEffect<AsteroidsGameState, AsteroidsGameAction>] = []
        
        if position.point.x > 480 {
            position.point.x = 0
        }
        if position.point.x < 0 {
            position.point.x = 480
        }
        if position.point.y > 480 {
            position.point.y = 0
        }
        if position.point.y < 0 {
            position.point.y = 480
        }
        
        if let keyboardInput = state.keyboardInput[ship.entity] {
            if keyboardInput.isAnyKeyPressed(in: [.upKey, .w]) {
                let y = cos(transform.rotate.degreesToRadians())
                let x = -sin(transform.rotate.degreesToRadians())
                let vector = Point(x: x, y: y) * (delta / 50)
                print(vector, delta)
                momentum.velocity.x += vector.x
                momentum.velocity.y += vector.y
                if momentum.velocity.distanceFrom(.zero) > 2 {
                    momentum.velocity.normalize(to: 2)
                }
            }
            if keyboardInput.isAnyKeyPressed(in: [.leftKey, .a]) {
                transform.rotate += 5
            }
            if keyboardInput.isAnyKeyPressed(in: [.rightKey, .d]) {
                transform.rotate -= 5
            }
            if keyboardInput.isKeyPressed(.space) {
                let y = cos(transform.rotate.degreesToRadians())
                let x = -sin(transform.rotate.degreesToRadians())
                let bulletDirection = Point(x: x, y: y)
                let bulletVelocity = bulletDirection * 1.2
                gameEffects += [generateBulletCreationActions(
                    position: position.point.offsetBy(bulletDirection * 25),
                    velocity: momentum.velocity + bulletVelocity
                )]
                
                print("entity count", state.entities.count)
            }
        }
        
        state.position[ship.entity] = position
        state.momentum[ship.entity] = momentum
        state.transform[ship.entity] = transform
        
        return .many(gameEffects)
    }
    
    public func reduce(
        state: inout AsteroidsGameState,
        action: AsteroidsGameAction,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
        switch action {
        case .newGame:
            return .many([
                generateShipCreationActions()
            ])
        case .keyboardInput:
            return .none
        }
    }
    
    func generateShipCreationActions() -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
        let shipId: EntityId = "ship"
        let ship = ShipComponent(entity: shipId)
        let shape = ShapeComponent(entity: shipId, shape: .polygon(ship.path))
        let position = PositionComponent(entity: shipId, point: .init(x: 100, y: 100))
        let movement = MovementComponent(entity: shipId, velocity: .zero, travelSpeed: 1)
        let transform = TransformComponent(entity: shipId)
        let momentum = MomentumComponent(entity: shipId, velocity: .zero)
        let keyboard = KeyboardInputComponent(entity: shipId)
        return .many([
            .system(.addEntity(shipId)),
            .system(.addComponent(ship, into: \.ship)),
            .system(.addComponent(shape, into: \.shape)),
            .system(.addComponent(position, into: \.position)),
            .system(.addComponent(movement, into: \.movement)),
            .system(.addComponent(transform, into: \.transform)),
            .system(.addComponent(momentum, into: \.momentum)),
            .system(.addComponent(keyboard, into: \.keyboardInput))
        ])
    }
    
    func generateBulletCreationActions(position: Point, velocity: Point) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
        let bulletId: EntityId = UUID().uuidString
        let shape = ShapeComponent(entity: bulletId, shape: .circle(.init(radius: 2)))
        let position = PositionComponent(entity: bulletId, point: position)
        let movement = MovementComponent(entity: bulletId, velocity: .zero, travelSpeed: 1)
        let momentum = MomentumComponent(entity: bulletId, velocity: velocity)
        return .many([
            .system(.addEntity(bulletId)),
            .system(.addComponent(shape, into: \.shape)),
            .system(.addComponent(position, into: \.position)),
            .system(.addComponent(movement, into: \.movement)),
            .system(.addComponent(momentum, into: \.momentum))
        ])
    }
}

public class AsteroidsGameScene: SKScene {
    
    var store: GameStore<AnyReducer<AsteroidsGameState, AsteroidsGameAction, SpriteRenderingEnvironment>>!
    
    public override init() {
        super.init(size: .init(width: 640, height: 480))
        store = GameStore(
            state: AsteroidsGameState(),
            environment: SpriteRenderingEnvironment(renderer: self),
            reducer: (
                AsteroidsGameReducer()
                + ShapeRenderingReducer()
                    .pullback(toLocalState: \.shapeContext)
                + MovementReducer()
                    .pullback(toLocalState: \.movementContext)
                + MomentumReducer()
                    .pullback(toLocalState: \.momentumContext)
                + KeyboardInputReducer()
                    .pullback(
                        toLocalState: \.keyboardInputContext,
                        toLocalAction: { globalAction in
                            switch globalAction {
                            case .keyboardInput(let keyAction):
                                return keyAction
                            default:
                                return nil
                            }
                        },
                        toGlobalAction: { .keyboardInput($0) }
                    )
            ).eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.position),
                .init(keyPath: \.movement),
                .init(keyPath: \.transform),
                .init(keyPath: \.momentum),
                .init(keyPath: \.shape),
                .init(keyPath: \.ship),
                .init(keyPath: \.keyboardInput)
            ]
        )
        
        store.sendAction(.newGame)
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
extension AsteroidsGameScene {

    public override func mouseDown(with event: NSEvent) {
        
    }
    
    public override func mouseDragged(with event: NSEvent) {

    }
    
    public override func mouseUp(with event: NSEvent) {
        
    }
    
    public override func keyDown(with event: NSEvent) {
        if let key = KeyboardInput(rawValue: event.keyCode) {
            store.sendAction(.keyboardInput(.keyDown(key)))
        } else {
            print("unmapped key down", event.keyCode)
        }
    }
    
    public override func keyUp(with event: NSEvent) {
        if let key = KeyboardInput(rawValue: event.keyCode) {
            store.sendAction(.keyboardInput(.keyUp(key)))
        } else {
            print("unmapped key up", event.keyCode)
        }
    }
}
#endif
