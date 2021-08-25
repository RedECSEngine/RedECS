//
//  GameViewController.swift
//  RedECSExample macOS
//
//  Created by Kyle Newsome on 2021-06-15.
//

import Cocoa
import SpriteKit
import GameplayKit
import RedECSExamples
import SwiftUI
import SpriteKit

struct SceneView<T: SKScene>: View {
    private var sceneType: T.Type
    @State private var isVisible: Bool = false
    
    init(sceneType: T.Type) {
        self.sceneType = sceneType
    }
   
    var body: some View {
        VStack {
            if isVisible {
                SpriteView(
                    scene: sceneType.init(),
                    options: [.shouldCullNonVisibleNodes, .ignoresSiblingOrder]
                )
            } else {
                EmptyView()
            }
        }
        .onAppear {
            self.isVisible = true
        }
        .onDisappear {
            self.isVisible = false
        }
    }
}

struct AppView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    "ExampleScene1",
                    destination: SceneView(sceneType: ExampleScene1.self)
                )
                NavigationLink(
                    "Separation",
                    destination: SceneView(sceneType: SeparationExampleScene.self)
                )
                NavigationLink(
                    "Follow/Separation/Pathing",
                    destination: SceneView(sceneType: FollowSeparationAndPathingExampleScene.self)
                )
                NavigationLink(
                    "Flocking",
                    destination: SceneView(sceneType: FlockingExampleScene.self)
                )
                NavigationLink(
                    "Follow/Flock/Path",
                    destination: SceneView(sceneType: FollowFlockingPathingExampleScene.self)
                )
            }
            HStack {
                Spacer()
                Text("Select an Example").font(.largeTitle)
                Spacer()
            }
        }
        
    }
}

class GameViewController: NSViewController {
    
    let vc = NSHostingController(rootView: AppView())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(vc)
        view.addSubview(vc.view)
        
        
//        let scene = FlockingExampleScene()
//
//        // Present the scene
//        let skView = self.view as! SKView
//        skView.presentScene(scene)
//
//        skView.ignoresSiblingOrder = true
//
//        skView.showsFPS = true
//        skView.showsNodeCount = true
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        vc.view.frame = view.frame
    }

}

