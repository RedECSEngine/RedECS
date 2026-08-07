import MetalKit
import Geometry
import RedECS

#if os(OSX)
import Cocoa

public typealias PlatformViewController = NSViewController
public typealias AppleColor = NSColor
#else
import UIKit

public typealias PlatformViewController = UIViewController
public typealias AppleColor = UIColor
#endif

public class MetalView: MTKView {
#if os(OSX)
    public override var acceptsFirstResponder: Bool { true }
#endif
}

open class AppleViewController: PlatformViewController {
    public var renderer: MetalRenderer!
    public var resourceManager: MetalResourceManager!
    public var soundEngine: AppleSoundEngine!
    public var mtkView: MetalView!
    open var shaderRegistry = ShaderRegistry() // override to register game shaders before load

    public var onPointerEvent: ((PointerEvent, Point) -> Void)?

    /// Converts a view-space location (points) to the renderer's viewport space
    /// (top-left origin, y-down, drawable pixels).
    private func viewportPoint(fromWindowPoint loc: CGPoint) -> Point {
        let bounds = mtkView.bounds
        let drawable = mtkView.drawableSize
        let sx = bounds.width > 0 ? drawable.width / bounds.width : 1
        let sy = bounds.height > 0 ? drawable.height / bounds.height : 1
#if os(OSX)
        let topLeftY = bounds.height - loc.y   // NSView is bottom-left origin
#else
        let topLeftY = loc.y                    // UIView is already top-left
#endif
        return Point(x: Double(loc.x * sx), y: Double(topLeftY * sy))
    }

#if os(OSX)
    open override func mouseDown(with event: NSEvent) {
        onPointerEvent?(.down, viewportPoint(fromWindowPoint: mtkView.convert(event.locationInWindow, from: nil)))
    }
    open override func mouseDragged(with event: NSEvent) {
        onPointerEvent?(.moved, viewportPoint(fromWindowPoint: mtkView.convert(event.locationInWindow, from: nil)))
    }
    open override func mouseUp(with event: NSEvent) {
        onPointerEvent?(.up, viewportPoint(fromWindowPoint: mtkView.convert(event.locationInWindow, from: nil)))
    }
#else
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        onPointerEvent?(.down, viewportPoint(fromWindowPoint: t.location(in: mtkView)))
    }
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        onPointerEvent?(.moved, viewportPoint(fromWindowPoint: t.location(in: mtkView)))
    }
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        onPointerEvent?(.up, viewportPoint(fromWindowPoint: t.location(in: mtkView)))
    }
#endif

    open override func loadView() {
        self.view = MetalView(frame: .init(origin: .zero, size: .init(width: 480, height: 480)))
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MetalView else {
            fatalError("View of Gameview controller is not an MTKView")
        }
        self.mtkView = mtkView

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }

        mtkView.device = defaultDevice
        
        let resourceManager = MetalResourceManager(metalDevice: defaultDevice)
        guard let newRenderer = MetalRenderer(
            device: defaultDevice,
            pixelFormat: mtkView.colorPixelFormat,
            resourceManager: resourceManager,
            shaderRegistry: shaderRegistry
        ) else {
            print("Renderer cannot be initialized")
            return
        }

        self.resourceManager = resourceManager
        self.renderer = newRenderer
        self.soundEngine = AppleSoundEngine()
        
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
    }
}
