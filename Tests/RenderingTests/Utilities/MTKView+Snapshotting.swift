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
          mtkView.framebufferOnly = false
          mtkView.drawableSize = mtkView.frame.size
          renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
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
