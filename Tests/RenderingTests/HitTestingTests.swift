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

class HitTestingTests: XCTestCase {
    var mtkView: MTKView!
    var renderer: MetalRenderer!
    var store: GameStore<AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment>>!
    
    var entityId = newEntityId()
    
    override func setUp() {
        super.setUp()
        
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
        (
            RenderingReducer(renderableComponentTypes: [
                .init(keyPath: \.sprite),
                .init(keyPath: \.shape)
            ])
                .pullback(
                    toLocalState: \.self,
                    toLocalEnvironment: { $0 as RenderingEnvironment }
                )
            +
            CameraReducer()
                .pullback(
                    toLocalState: \.cameraContext,
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
                .init(keyPath: \.shape),
                .init(keyPath: \.camera),
            ])
        
        let shape = ShapeComponent(
            entity: entityId ,
            shape: .rect(.init(origin: .zero, size: .init(width: 120, height: 120))),
            fillColor: .red
        )
        
        let camera = CameraComponent(entity: entityId)
       
        store.sendSystemAction(.addEntity(entityId, []))
        store.sendSystemAction(.addComponent(shape, into: \.shape))
        store.sendSystemAction(.addComponent(camera, into: \.camera))
    }
    
    func testShapeContainsPoint() {
        let point = Point(x: 10, y: 10)
        let shape = store.state.shape[entityId]!
        let transform = TransformComponent(entity: entityId, anchorPoint: .zero)
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        
        enqueueGrid(into: renderer)
        enqueuePoint(point, into: renderer)
        store.sendDelta(1)
        
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
        XCTAssertEqual(shape.contains(point, whenTransformedBy: transform.matrix(containerSize: shape.rect.size)), true)
    }
    
    func testShapeTransformAndRotateDoesNotContainPoint() throws {
        let point = Point(x: 10, y: 10)
        let shape = store.state.shape[entityId]!
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
        XCTAssertEqual(shape.contains(point, whenTransformedBy: transform.matrix(containerSize: shape.rect.size)), false)
    }
    
    func testShapeTransformAndRotateContainsPoint() throws {
        let point = Point(x: 210, y: 50)
        let shape = store.state.shape[entityId]!
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
        let matrix = transform.matrix(containerSize: shape.rect.size)
        XCTAssertEqual(shape.contains(point, whenTransformedBy: matrix), true)
    }
    
    func testShapeTransformAndRotateContainsPointAtZero() throws {
        let point = Point(x: 220, y: 120)
        let shape = store.state.shape[entityId]!
        let transform = TransformComponent(
            entity: entityId,
            position: .init(x: 220, y: 120),
            anchorPoint: .zero,
            rotate: -45
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        
        enqueueGrid(into: renderer)
        enqueuePoint(point, into: renderer)
        store.sendDelta(1)
        
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
        let matrix = transform.matrix(containerSize: shape.rect.size)
        XCTAssertEqual(shape.contains(point, whenTransformedBy: matrix), true)
        XCTAssertEqual(point.multiplyingMatrix(matrix.calculateInverse()), .zero)
    }
    
    func testShapeTransformAndRotateContainsPointAtCenter() throws {
        let point = Point(x: 220, y: 120)
        let shape = store.state.shape[entityId]!
        let transform = TransformComponent(
            entity: entityId,
            position: .init(x: 220, y: 120),
            anchorPoint: .init(x: 0.5, y: 0.5),
            rotate: -45
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        
        enqueueGrid(into: renderer)
        enqueuePoint(point, into: renderer)
        store.sendDelta(1)
        
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
        let matrix = transform.matrix(containerSize: shape.rect.size)
        XCTAssertEqual(shape.contains(point, whenTransformedBy: matrix), true)
        
        XCTAssertEqual(point.multiplyingMatrix(matrix.calculateInverse()).rounded(), .init(x: 60, y: 60))
    }
    
    func testShapePointContainmentWhenTransformedFromCameraSpace() {
        let shape = store.state.shape[entityId]!
        let transform = TransformComponent(
            entity: entityId,
            position: .zero,
            anchorPoint: .zero
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        store.sendDelta(1)
        renderer.clearQueue()

        var camera = store.state.camera.values.first!
        let screenTouchPoint = Point(x: 0.4, y: 0.4)
        let shapeMatrix = transform.matrix(containerSize: shape.rect.size)
        
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
        let shape = store.state.shape[entityId]!
        let transform = TransformComponent(
            entity: entityId,
            position: .init(x: 120, y: 120),
            anchorPoint: .init(x: 0.5, y: 0.5)
        )
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        store.sendDelta(1)
        renderer.clearQueue()

        var camera = store.state.camera.values.first!
        let screenTouchPoint = Point(x: 0.4, y: 0.4)
        let shapeMatrix = transform.matrix(containerSize: shape.rect.size)
        
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
