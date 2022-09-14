//
//  CameraRenderingTests.swift
//
//
//  Created by K N on 2022-08-18.
//

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

class CameraRenderingTests: XCTestCase {
    var mtkView: MTKView!
    var renderer: MetalRenderer!
    var store: GameStore<AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment>>!
        
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
    }

    func testCameraRender() throws {
        let entityId = newEntityId()
        let shape = ShapeComponent(
            entity: entityId ,
            shape: .triangle(Triangle(
                a: .zero,
                b: .init(x: 0, y: 240),
                c: .init(x: 240, y: 0)
            )),
            fillColor: .red
        )
        let transform = TransformComponent(entity: entityId, position: .zero, anchorPoint: .zero)
        let camera = CameraComponent(entity: entityId)
        
        store.sendSystemAction(.addEntity(entityId, []))
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        store.sendSystemAction(.addComponent(shape, into: \.shape))
        store.sendSystemAction(.addComponent(camera, into: \.camera))
        
        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: "first pass")
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: "second pass")
    }
    
    func testCameraRenderOffset() throws {
        let entityId = newEntityId()
        let shape = ShapeComponent(
            entity: entityId ,
            shape: .triangle(Triangle(
                a: .zero,
                b: .init(x: 0, y: 240),
                c: .init(x: 240, y: 0)
            )),
            fillColor: .red
        )
        let transform = TransformComponent(entity: entityId, position: .init(x: 100, y: 100), anchorPoint: .zero)
        let camera = CameraComponent(entity: entityId)
        
        store.sendSystemAction(.addEntity(entityId, []))
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        store.sendSystemAction(.addComponent(shape, into: \.shape))
        store.sendSystemAction(.addComponent(camera, into: \.camera))
       
        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
    }
    
    func testCameraRenderZoom() throws {
        let entityId = newEntityId()
        let shape = ShapeComponent(
            entity: entityId ,
            shape: .triangle(Triangle(
                a: .zero,
                b: .init(x: 0, y: 240),
                c: .init(x: 240, y: 0)
            )),
            fillColor: .red
        )
        let transform = TransformComponent(
            entity: entityId,
            position: .zero,
            anchorPoint: .zero
        )
        let camera = CameraComponent(entity: entityId, zoom: 0.5)
        
        store.sendSystemAction(.addEntity(entityId, []))
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        store.sendSystemAction(.addComponent(shape, into: \.shape))
        store.sendSystemAction(.addComponent(camera, into: \.camera))
       
        enqueueGrid(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
//        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: "temp", record: true)
    }
    
    
}
