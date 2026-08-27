import XCTest
import SnapshotTesting
import RedECS
@testable import RedECSAppleSupport
import MetalKit
import CoreImage
import CoreGraphics
import Geometry
import GeometryAlgorithms
import RedECSBasicComponents

@MainActor
class SceneTransitionTests: XCTestCase {
    var mtkView: MTKView!
    var renderer: MetalRenderer!
    var store: GameStore<AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment>>!

    override func setUp() async throws {
        let device = MTLCreateSystemDefaultDevice()!
        self.mtkView = MTKView(
            frame: .init(origin: .zero, size: .init(width: 480, height: 480)),
            device: device
        )
        self.renderer = MetalRenderer(
            device: device,
            pixelFormat: mtkView.colorPixelFormat,
            resourceManager: MetalResourceManager(metalDevice: device)
        )
        mtkView.delegate = renderer
        renderer.mtkView(mtkView, drawableSizeWillChange: .init(width: 480, height: 480))

        let reducer: AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment> =
        RenderingReducer.sceneAware(renderableComponentTypes: [
            .init(keyPath: \.sprite)
        ])
            .pullback(
                toLocalState: \.self,
                toLocalEnvironment: { $0 as RenderingEnvironment }
            )
            .eraseToAnyReducer()

        store = GameStore(
            state: RenderingTestState(),
            environment: RenderingTestEnvironment(
                metalRenderer: renderer,
                metalResourceManager: renderer.resourceManager
            ),
            reducer: reducer,
            registeredComponentTypes: [
                .init(keyPath: \.transform),
                .init(keyPath: \.sprite),
                .init(keyPath: \.camera),
                .init(keyPath: \.scene),
            ])

        let cameraId = "camera"
        store.sendSystemAction(.addEntity(cameraId, []))
        store.sendSystemAction(.addComponent(TransformComponent(entity: cameraId, position: .init(x: 240, y: 240)), into: \.transform))
        store.sendSystemAction(.addComponent(CameraComponent(entity: cameraId), into: \.camera))

        addScene("sceneA")
        addSquare("aSquare", parent: "sceneA", position: .init(x: 60, y: 60), size: 240, color: .green)
        addSquare("aAccent", parent: "sceneA", position: .init(x: 300, y: 300), size: 100, color: .yellow)

        addScene("sceneB")
        addSquare("bSquare", parent: "sceneB", position: .init(x: 180, y: 180), size: 240, color: .blue)
        addSquare("bAccent", parent: "sceneB", position: .init(x: 80, y: 320), size: 100, color: .pink)
    }

    private func addScene(_ id: EntityId) {
        store.sendSystemAction(.addEntity(id, []))
        store.sendSystemAction(.addComponent(TransformComponent(entity: id), into: \.transform))
        store.sendSystemAction(.addComponent(SceneComponent(entity: id), into: \.scene))
    }

    private func addSquare(
        _ id: EntityId,
        parent: EntityId?,
        position: Point,
        size: Double,
        color: Color
    ) {
        store.sendSystemAction(.addEntity(id, []))
        if let parent = parent {
            store.sendSystemAction(.setParent(id, parent))
        }
        store.sendSystemAction(.addComponent(
            TransformComponent(entity: id, position: position),
            into: \.transform
        ))
        store.sendSystemAction(.addComponent(
            SpriteComponent(
                entity: id,
                shape: .rect(.init(origin: .zero, size: .init(width: size, height: size))),
                fillColor: color,
                anchorPoint: .zero
            ),
            into: \.sprite
        ))
    }

    private func snapshotTransitionFrame(
        elapsed: Double,
        transition: SceneTransition,
        named name: String,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        store.perform { state, _ in
            state.sceneManager.transition = ActiveSceneTransition(
                outgoingSceneId: "sceneA",
                incomingSceneId: "sceneB",
                transition: transition,
                elapsed: elapsed
            )
            return .none
        }
        renderer.clearQueue()
        store.sendDelta(1)
        assertSnapshot(
            matching: mtkView,
            as: .image(renderer: renderer),
            named: name,
            file: file,
            testName: testName,
            line: line
        )
    }

    func testDissolveTransitionTimeline() throws {
        store.perform { state, _ in
            state.sceneManager.activeSceneId = "sceneA"
            return .none
        }
        let transition = SceneTransition.dissolve(duration: 1)
        snapshotTransitionFrame(elapsed: 0.02, transition: transition, named: "start")
        snapshotTransitionFrame(elapsed: 0.5, transition: transition, named: "middle")
        snapshotTransitionFrame(elapsed: 0.98, transition: transition, named: "end")
    }

    func testSequentialFadeTimeline() throws {
        store.perform { state, _ in
            state.sceneManager.activeSceneId = "sceneA"
            return .none
        }
        let transition = SceneTransition.fade(duration: 1)
        snapshotTransitionFrame(elapsed: 0.25, transition: transition, named: "outgoing-half-faded")
        snapshotTransitionFrame(elapsed: 0.75, transition: transition, named: "incoming-half-faded")
    }
}
