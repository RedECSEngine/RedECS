//
//  MTKView+Snapshotting.swift
//
//
//  Created by K N on 2022-08-19.
//

import MetalKit
import SnapshotTesting
import RedECSAppleSupport

extension Snapshotting where Value == MTKView, Format == NSImage {
  /// A snapshot strategy for comparing images based on pixel equality.
    public static func image(renderer: MetalRenderer) -> Snapshotting {
      Snapshotting<NSImage, NSImage>.image(precision: 1).pullback { mtkView in
          // Snapshot strategies are invoked on the main thread under XCTest,
          // but the pullback closure itself is nonisolated.
          nonisolated(unsafe) let view = mtkView
          nonisolated(unsafe) let renderer = renderer
          nonisolated(unsafe) var image: NSImage!
          MainActor.assumeIsolated {
              view.framebufferOnly = false
              view.drawableSize = view.frame.size
              renderer.mtkView(view, drawableSizeWillChange: view.drawableSize)
              renderer.draw(in: view)
              let texture = view.currentDrawable!.texture
              let ciImage = CIImage(mtlTexture: texture)!
              let flipped = ciImage.transformed(by: CGAffineTransform(scaleX: 1, y: -1))
              let opt = [CIContextOption.outputPremultiplied: true,
                         CIContextOption.useSoftwareRenderer: false]
              let cont = CIContext(options: opt)
              let cgImage = cont.createCGImage(flipped, from: flipped.extent)!
              image = NSImage(cgImage: cgImage, size: view.frame.size)
          }
          return image
      }
  }
}
