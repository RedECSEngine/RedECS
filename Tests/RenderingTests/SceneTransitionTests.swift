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
        zip(
            OperationReducer<RenderingTestAction>()
                .pullback(toLocalState: \.operationContext),
            RenderingReducer(renderableComponentTypes: [
                .init(keyPath: \.sprite)
            ])
                .pullback(
                    toLocalState: \.self,
                    toLocalEnvironment: { $0 as RenderingEnvironment }
                )
        ).eraseToAnyReducer()

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
                .init(keyPath: \.operation),
            ])

        let cameraId = "camera"
        store.sendSystemAction(.addEntity(cameraId, []))
        store.sendSystemAction(.addComponent(TransformComponent(entity: cameraId, position: .init(x: 240, y: 240)), into: \.transform))
        store.sendSystemAction(.addComponent(CameraComponent(entity: cameraId), into: \.camera))

        addSceneRoot("sceneA", hidden: false)
        addSquare("aSquare", parent: "sceneA", position: .init(x: 60, y: 60), size: 240, color: .green)
        addSquare("aAccent", parent: "sceneA", position: .init(x: 300, y: 300), size: 100, color: .yellow)

        addSceneRoot("sceneB", hidden: true)
        addSquare("bSquare", parent: "sceneB", position: .init(x: 180, y: 180), size: 240, color: .blue)
        addSquare("bAccent", parent: "sceneB", position: .init(x: 80, y: 320), size: 100, color: .pink)
    }

    private func addSceneRoot(_ id: EntityId, hidden: Bool) {
        store.sendSystemAction(.addEntity(id, []))
        var transform = TransformComponent(entity: id)
        transform.isHidden = hidden
        store.sendSystemAction(.addComponent(transform, into: \.transform))
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

    private func snapshotFrame(
        delta: Double,
        named name: String,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        renderer.clearQueue()
        store.sendDelta(delta)
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
        store.handleEffect(.presentScene(hide: "sceneA", show: "sceneB", transition: .dissolve(duration: 1)))
        snapshotFrame(delta: 0.02, named: "start")
        snapshotFrame(delta: 0.48, named: "middle")
        snapshotFrame(delta: 0.48, named: "end")
    }

    func testSequentialFadeTimeline() throws {
        store.handleEffect(.presentScene(hide: "sceneA", show: "sceneB", transition: .fade(duration: 1)))
        snapshotFrame(delta: 0.25, named: "outgoing-half-faded")
        renderer.clearQueue()
        store.sendDelta(0.25)
        renderer.clearQueue()
        store.sendDelta(0.1)
        snapshotFrame(delta: 0.25, named: "incoming-half-faded")
    }
}
