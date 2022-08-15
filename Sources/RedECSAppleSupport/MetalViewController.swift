import MetalKit

#if os(OSX)
import Cocoa

public typealias AppleViewController = NSViewController
public typealias AppleColor = NSColor
#else
import UIKit

public typealias AppleViewController = UIViewController
public typealias AppleColor = UIColor
#endif

open class MetalViewController: AppleViewController {
    public var renderer: MetalRenderer!
    public var resourceManager: MetalResourceManager!
    public var mtkView: MTKView!
    
    open override func loadView() {
        self.view = MTKView(frame: .init(origin: .zero, size: .init(width: 480, height: 480)))
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            fatalError("View of Gameview controller is not an MTKView")
        }
        self.mtkView = mtkView

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }

        mtkView.device = defaultDevice
        
        let resourceManager = MetalResourceManager(metalDevice: defaultDevice)
        guard let newRenderer = MetalRenderer(mtkView: mtkView, resourceManager: resourceManager) else {
            print("Renderer cannot be initialized")
            return
        }

        self.resourceManager = resourceManager
        self.renderer = newRenderer
        
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
    }
}
