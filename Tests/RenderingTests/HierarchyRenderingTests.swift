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
class HierarchyRenderingTests: XCTestCase {
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

        // camera on its own root-level entity so the hierarchy under test
        // doesn't affect the projection
        let cameraId = "camera"
        store.sendSystemAction(.addEntity(cameraId, []))
        store.sendSystemAction(.addComponent(TransformComponent(entity: cameraId, position: .init(x: 120, y: 120)), into: \.transform))
        store.sendSystemAction(.addComponent(CameraComponent(entity: cameraId), into: \.camera))
    }

    private func addSquare(
        _ id: EntityId,
        parent: EntityId? = nil,
        position: Point,
        rotate: Double = 0,
        scale: Point = .init(x: 1, y: 1),
        size: Double = 60,
        color: Color
    ) {
        store.sendSystemAction(.addEntity(id, []))
        if let parent = parent {
            store.sendSystemAction(.setParent(id, parent))
        }
        store.sendSystemAction(.addComponent(
            TransformComponent(entity: id, position: position, rotate: rotate, scale: scale),
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

    /// A child positioned at a local offset renders inside its parent's
    /// translated and rotated frame; the grandchild compounds again.
    func testChildrenRenderInParentFrame() throws {
        addSquare("parent", position: .init(x: 120, y: 120), rotate: 30, size: 80, color: .red)
        addSquare("child", parent: "parent", position: .init(x: 100, y: 0), size: 50, color: .green)
        addSquare("grandchild", parent: "child", position: .init(x: 70, y: 0), rotate: 45, size: 30, color: .blue)

        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
    }

    /// A parent's scale multiplies through to its children.
    func testParentScaleAppliesToChildren() throws {
        addSquare("parent", position: .init(x: 60, y: 60), scale: .init(x: 2, y: 2), size: 40, color: .red)
        addSquare("child", parent: "parent", position: .init(x: 60, y: 0), size: 40, color: .green)

        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
    }

    /// Hiding a parent hides its whole subtree; unhiding restores it.
    func testHiddenParentHidesSubtree() throws {
        addSquare("visible", position: .init(x: 20, y: 180), size: 40, color: .blue)
        addSquare("parent", position: .init(x: 100, y: 100), size: 60, color: .red)
        addSquare("child", parent: "parent", position: .init(x: 80, y: 0), size: 40, color: .green)

        store.perform { state, _ in
            state.transform["parent"]?.isHidden = true
            return .none
        }

        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: "hidden")

        store.perform { state, _ in
            state.transform["parent"]?.isHidden = false
            return .none
        }

        renderer.clearQueue()
        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: "unhidden")
    }

    /// A parent's rotation pivots around its anchor point, and children orbit
    /// that same pivot. The anchor offsets the parent's own drawing only —
    /// children stay attached to the pivot (SpriteKit semantics).
    func testParentAnchorPointIsTheSharedPivot() throws {
        // center-anchored: content is centered on the pivot
        store.sendSystemAction(.addEntity("centered", []))
        store.sendSystemAction(.addComponent(
            TransformComponent(entity: "centered", position: .init(x: 60, y: 170), rotate: 40),
            into: \.transform
        ))
        store.sendSystemAction(.addComponent(
            SpriteComponent(entity: "centered", shape: .rect(.init(origin: .zero, size: .init(width: 80, height: 80))), fillColor: .red, anchorPoint: .init(x: 0.5, y: 0.5)),
            into: \.sprite
        ))
        addSquare("centeredChild", parent: "centered", position: .init(x: 70, y: 0), size: 24, color: .green)

        // zero-anchored: content's corner is on the pivot, same rotation
        addSquare("cornered", position: .init(x: 170, y: 60), rotate: 40, size: 80, color: .blue)
        addSquare("corneredChild", parent: "cornered", position: .init(x: 70, y: 0), size: 24, color: .yellow)

        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
    }

    /// Reparenting at runtime moves the child into the new parent's frame.
    func testReparentingMovesChildFrame() throws {
        addSquare("left", position: .init(x: 20, y: 100), size: 50, color: .red)
        addSquare("right", position: .init(x: 170, y: 100), rotate: 45, size: 50, color: .blue)
        addSquare("child", parent: "left", position: .init(x: 0, y: 70), size: 30, color: .green)

        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: "under left")

        store.sendSystemAction(.setParent("child", "right"))

        renderer.clearQueue()
        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: "under right")
    }
}
