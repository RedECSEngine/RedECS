//
//  RenderingTests.swift
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

class MetalRenderingTests: XCTestCase {
    
    var mtkView: MTKView!
    var renderer: MetalRenderer!
    
    var bottomLeftTriangle = RenderGroup(
        triangles: [
            RenderTriangle(triangle: .init(
                a: .zero,
                b: .init(x: 0, y: 240),
                c: .init(x: 240, y: 0)
            ))
        ],
        transformMatrix: .identity.translatedBy(tx: 240, ty: 240),
        fragmentType: .color(.red),
        zIndex: 1
    )
    
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
        
        renderer.projectionMatrix = Matrix3.projection(width: 480, height: 480).asMatrix4x4
        mtkView.delegate = renderer
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }

    func testTrianglePointingBottomLeft() throws {
        renderer.enqueue([bottomLeftTriangle])
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
    }
    
    func testTriangleInBottomLeftRotatedAround0_0AnchorPoint() throws {
        for i in 0...4 {
            renderer.enqueue([
                bottomLeftTriangle
                    .withAdjustedMatrix(
                        .identity
                            .rotatedBy(angleInRadians: Double(i * 45).degreesToRadians())
                    )
                    .withAdjustedColor(Color(red: (45 + Double(45 * i)) / 255, green: 0, blue: 0, alpha: 1))
            ])
        }
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
    }
    
    func testTriangleInBottomLeftRotatedAround0_5_0_5AnchorPoint() throws {
        for i in 0...4 {
            renderer.enqueue([
                bottomLeftTriangle
                    .withAdjustedMatrix(
                        .identity
                            .rotatedBy(angleInRadians: Double(i * 45).degreesToRadians())
                            .translatedBy(tx: -120, ty: -120)
                    )
                    .withAdjustedColor(Color(red: (45 + Double(45 * i)) / 255, green: 0, blue: 0, alpha: 1))
            ])
        }
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
    }
    
    
    func testTriangleInBottomLeftRotatedAround1_1AnchorPoint() throws {
        for i in 0...3 {
            renderer.enqueue([
                bottomLeftTriangle
                    .withAdjustedMatrix(
                        .identity
                            .rotatedBy(angleInRadians: Double(i * 90).degreesToRadians())
                            .translatedBy(tx: -240, ty: -240)
                    )
                    .withAdjustedColor(Color(red: (45 + Double(45 * i)) / 255, green: 0, blue: 0, alpha: 1))
            ])
        }
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer))
    }
    
}

extension RenderGroup {
    func withAdjustedMatrix(_ adjustMatrix: Matrix3) -> RenderGroup {
        RenderGroup(
            triangles: triangles,
            transformMatrix: .multiply(transformMatrix, adjustMatrix),
            fragmentType: fragmentType,
            zIndex: zIndex
        )
    }
    
    func withAdjustedColor(_ color: Color) -> RenderGroup {
        switch fragmentType {
        case .texture:
            return self
        case .color:
            return RenderGroup(
                triangles: triangles,
                transformMatrix: transformMatrix,
                fragmentType: .color(color),
                zIndex: zIndex
            )
        }
    }
}

extension Snapshotting where Value == MTKView, Format == NSImage {
  /// A snapshot strategy for comparing images based on pixel equality.
    public static func image(renderer: MetalRenderer) -> Snapshotting {
      Snapshotting<NSImage, NSImage>.image(precision: 1).pullback { mtkView in
          mtkView.framebufferOnly = false
          mtkView.drawableSize = mtkView.frame.size
          renderer.draw(in: mtkView)
          let texture = mtkView.currentDrawable!.texture
          let ciImage = CIImage(mtlTexture: texture)!
          let flipped = ciImage.transformed(by: CGAffineTransform(scaleX: 1, y: -1))
          let opt = [CIContextOption.outputPremultiplied: true,
                     CIContextOption.useSoftwareRenderer: false]
          let cont = CIContext(options: opt)
          let cgImage = cont.createCGImage(flipped, from: flipped.extent)!
          return NSImage(cgImage: cgImage, size: mtkView.frame.size)
      }
  }
}
