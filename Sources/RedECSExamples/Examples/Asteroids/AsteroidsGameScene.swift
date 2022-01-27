import Foundation
import SpriteKit
import RedECS
import RedECSBasicComponents
import RedECSRenderingComponents
import Geometry

public enum AsteroidsGameAction: Equatable & Codable {
    case newGame
    case keyboardInput(KeyboardInputAction)
    case rotateLeft
    case rotateRight
    case propelForward
    case fireBullet
}

public class AsteroidsGameScene: SKScene {
    
    var store: GameStore<AnyReducer<AsteroidsGameState, AsteroidsGameAction, SpriteRenderingEnvironment>>!
    
    public override init() {
        super.init(size: .init(width: 640, height: 480))
        store = GameStore(
            state: AsteroidsGameState(),
            environment: SpriteRenderingEnvironment(renderer: self),
            reducer: (
                zip(AsteroidsPositioningReducer(), AsteroidsInputReducer(), AsteroidsCollisionReducer())
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
                + KeyboardKeyMapReducer()
                    .pullback(
                        toLocalState: \.keyboardInputContext
                    )
            ).eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.position),
                .init(keyPath: \.movement),
                .init(keyPath: \.transform),
                .init(keyPath: \.momentum),
                .init(keyPath: \.shape),
                .init(keyPath: \.ship),
                .init(keyPath: \.asteroid),
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
