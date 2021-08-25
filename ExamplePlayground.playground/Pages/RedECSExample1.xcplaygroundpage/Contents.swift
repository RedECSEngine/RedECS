//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit
import RedECS
import RedECSExamples


// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))

let scene = ExampleScene()
// Set the scale mode to scale to fit the window
scene.scaleMode = .aspectFill

// Present the scene
sceneView.presentScene(scene)

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView

