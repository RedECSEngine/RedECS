//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameSprite: SKShapeNode {
    var velocityX: CGFloat = 0
    var velocityY: CGFloat = 0
    var boundsX: CGFloat = 0
    var boundsY: CGFloat = 0
}

class GameScene: SKScene {
    override init() {
        super.init(size: .init(width: 640, height: 480))
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) { nil }
    
    override func update(_ currentTime: TimeInterval) {
        for node in children {
            guard let node = node as? GameSprite else { return }
            if node.parent == nil {
                addChild(node)
            }
            
            if node.position.x + node.velocityX > node.boundsX {
                node.position.x = 0
            }
            else if node.position.x + node.velocityX < 0 {
                node.position.x = node.boundsX
            }
            else {
                node.position.x += node.velocityX
            }
            if node.position.y + node.velocityY > node.boundsY {
                node.position.y = 0
            }
            else if node.position.y + node.velocityY < 0 {
                node.position.y = node.boundsY
            }
            else {
                node.position.y += node.velocityY
            }
        }
    }
    
}

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        
    }
    
    override func mouseDragged(with event: NSEvent) {
        DispatchQueue.global(qos: .userInteractive).async {
            let sprite = GameSprite(rect: .init(origin: .zero, size: .init(width: 30, height: 30)))
            sprite.velocityX = .random(in: -10...10)
            sprite.velocityY = .random(in: -10...10)
            sprite.boundsX = 640
            sprite.boundsY = 480
            sprite.fillColor = .init(
                red: .random(in: 0...1),
                green: .random(in: 0...1),
                blue: .random(in: 0...1),
                alpha: 1
            )
            sprite.position = event.location(in: self)
            DispatchQueue.main.async {            
                self.addChild(sprite)
            }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        
    }

}
#endif

// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))

let scene = GameScene()
// Set the scale mode to scale to fit the window
scene.scaleMode = .aspectFill

// Present the scene
sceneView.presentScene(scene)

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView

