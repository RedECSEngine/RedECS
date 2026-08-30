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
class HitTestingTests: XCTestCase {
    var mtkView: MTKView!
    var renderer: MetalRenderer!
    var store: GameStore<AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment>>!

    var entityId = newEntityId()

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
        RenderingReducer(renderableComponentTypes: [
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
            ])

        let sprite = SpriteComponent(
            entity: entityId,
            shape: .rect(.init(origin: .zero, size: .init(width: 120, height: 120))),
            fillColor: .red
        )

        let camera = CameraComponent(entity: entityId)

        store.sendSystemAction(.addEntity(entityId, []))
        store.sendSystemAction(.addComponent(sprite, into: \.sprite))
        store.sendSystemAction(.addComponent(camera, into: \.camera))
    }

    private func setSpriteAnchor(_ anchorPoint: Point) {
        store.perform { state, _ in
            state.sprite[entityId]?.setAnchorPoint(anchorPoint)
            return .none
        }
    }

    func testShapeContainsPoint() {
        let point = Point(x: 10, y: 10)
        setSpriteAnchor(.zero)
        let sprite = store.state.sprite[entityId]!
        let shape = sprite.shapeValue!
        let transform = TransformComponent(entity: entityId)
        store.sendSystemAction(.addComponent(transform, into: \.transform))

        enqueueGrid(into: renderer)
        enqueuePoint(point, into: renderer)
        store.sendDelta(1)

        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
        XCTAssertEqual(shape.contains(point, whenTransformedBy: sprite.contentMatrix(transform: transform, containerSize: shape.rect.size)), true)
    }

    func testShapeTransformAndRotateDoesNotContainPoint() throws {
        let point = Point(x: 10, y: 10)
        let sprite = store.state.sprite[entityId]!
        let shape = sprite.shapeValue!
        let transform = TransformComponent(
            entity: entityId,
            position: .init(x: 120, y: 120),
            rotate: -45
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))

        enqueueGrid(into: renderer)
        enqueuePoint(point, into: renderer)
        store.sendDelta(1)

        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
        XCTAssertEqual(shape.contains(point, whenTransformedBy: sprite.contentMatrix(transform: transform, containerSize: shape.rect.size)), false)
    }

    func testShapeTransformAndRotateContainsPoint() throws {
        let point = Point(x: 210, y: 50)
        let sprite = store.state.sprite[entityId]!
        let shape = sprite.shapeValue!
        let transform = TransformComponent(
            entity: entityId,
            position: .init(x: 220, y: 120),
            rotate: -45
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))

        enqueueGrid(into: renderer)
        enqueuePoint(point, into: renderer)
        store.sendDelta(1)

        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
        let matrix = sprite.contentMatrix(transform: transform, containerSize: shape.rect.size)
        XCTAssertEqual(shape.contains(point, whenTransformedBy: matrix), true)
    }

    func testShapeTransformAndRotateContainsPointAtZero() throws {
        let point = Point(x: 220, y: 120)
        setSpriteAnchor(.zero)
        let sprite = store.state.sprite[entityId]!
        let shape = sprite.shapeValue!
        let transform = TransformComponent(
            entity: entityId,
            position: .init(x: 220, y: 120),
            rotate: -45
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))

        enqueueGrid(into: renderer)
        enqueuePoint(point, into: renderer)
        store.sendDelta(1)

        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
        let matrix = sprite.contentMatrix(transform: transform, containerSize: shape.rect.size)
        XCTAssertEqual(shape.contains(point, whenTransformedBy: matrix), true)
        XCTAssertEqual(point.multiplyingMatrix(matrix.calculateInverse()), .zero)
    }

    func testShapeTransformAndRotateContainsPointAtCenter() throws {
        let point = Point(x: 220, y: 120)
        setSpriteAnchor(.init(x: 0.5, y: 0.5))
        let sprite = store.state.sprite[entityId]!
        let shape = sprite.shapeValue!
        let transform = TransformComponent(
            entity: entityId,
            position: .init(x: 220, y: 120),
            rotate: -45
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))

        enqueueGrid(into: renderer)
        enqueuePoint(point, into: renderer)
        store.sendDelta(1)

        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
        let matrix = sprite.contentMatrix(transform: transform, containerSize: shape.rect.size)
        XCTAssertEqual(shape.contains(point, whenTransformedBy: matrix), true)

        XCTAssertEqual(point.multiplyingMatrix(matrix.calculateInverse()).rounded(), .init(x: 60, y: 60))
    }

    func testShapePointContainmentWhenTransformedFromCameraSpace() {
        setSpriteAnchor(.zero)
        let sprite = store.state.sprite[entityId]!
        let shape = sprite.shapeValue!
        let transform = TransformComponent(
            entity: entityId,
            position: .zero
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        store.sendDelta(1)
        renderer.clearQueue()

        var camera = store.state.camera.values.first!
        let screenTouchPoint = Point(x: 0.4, y: 0.4)
        let shapeMatrix = sprite.contentMatrix(transform: transform, containerSize: shape.rect.size)

        // Pre-Zoom test

        let cameraMatrixBeforeZoom = camera.matrix(withRect: Rect(center: transform.position, size: renderer.viewportSize))
        let pointInWorldSpaceBeforeZoom = screenTouchPoint.multiplyingMatrix(cameraMatrixBeforeZoom.calculateInverse())

        enqueueGrid(into: renderer)
        store.sendDelta(1)
        enqueuePoint(pointInWorldSpaceBeforeZoom, into: renderer)

        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: "before zoom")
        XCTAssertEqual(shape.contains(pointInWorldSpaceBeforeZoom, whenTransformedBy: shapeMatrix), true)

        // Zoom Test

        renderer.clearQueue()
        store.perform { state, _ in
            camera.zoom = 0.5
            state.camera[camera.entity] = camera
            return .none
        }
        let cameraMatrixAfter = camera.matrix(withRect: Rect(center: transform.position, size: renderer.viewportSize))
        let pointInWorldSpaceAfterZoom = screenTouchPoint.multiplyingMatrix(cameraMatrixAfter.calculateInverse())

        enqueueGrid(into: renderer)
        store.sendDelta(1)
        enqueuePoint(pointInWorldSpaceAfterZoom, into: renderer)

        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: "after zoom")
        XCTAssertEqual(shape.contains(pointInWorldSpaceAfterZoom, whenTransformedBy: shapeMatrix), false)
    }


    func testCameraRenderZoomWithObjectTranslate() throws {
        setSpriteAnchor(.init(x: 0.5, y: 0.5))
        let sprite = store.state.sprite[entityId]!
        let shape = sprite.shapeValue!
        let transform = TransformComponent(
            entity: entityId,
            position: .init(x: 120, y: 120)
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        store.sendDelta(1)
        renderer.clearQueue()

        var camera = store.state.camera.values.first!
        let screenTouchPoint = Point(x: 0.4, y: 0.4)
        let shapeMatrix = sprite.contentMatrix(transform: transform, containerSize: shape.rect.size)

        // Zoom Test

        store.perform { state, _ in
            camera.zoom = 2
            state.camera[camera.entity] = camera
            return .none
        }
        let cameraMatrixAfter = camera.matrix(withRect: Rect(center: transform.position, size: renderer.viewportSize))
        let pointInWorldSpaceAfterZoom = screenTouchPoint.multiplyingMatrix(cameraMatrixAfter.calculateInverse())

        enqueueGrid(into: renderer)
        store.sendDelta(1)
        enqueuePoint(pointInWorldSpaceAfterZoom, into: renderer)

        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
        XCTAssertEqual(shape.contains(pointInWorldSpaceAfterZoom, whenTransformedBy: shapeMatrix), true)
    }
}
