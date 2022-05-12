import JavaScriptKit
import RedECSBasicComponents
import Geometry

open class WebBrowserWindow {
    
    public var renderer: WebRenderer!
    
    public required init(size: Size) {
        self.renderer = WebRenderer(size: size, stateChangeHandler: { [weak self] _, newValue in
            if newValue == .ready {
                self?.onWebRendererReady()
            }
        })
    }
    
    open func onWebRendererReady() {
        print("web rendering ready")
        addListeners()
        requestAnimationFrame()
    }
    
    private func addListeners() {
        let document = JSObject.global.document
        _ = document.addEventListener("keydown", JSClosure { [weak self] args in
            if let key = args.first?.object?.code.string,
               let input = WebBrowserKeyboardInput(rawValue: key) {
                self?.onKeyDown(input.keyboardInput)
            }
            return .undefined
        })
        _ = document.addEventListener("keyup", JSClosure { [weak self] args in
            if let key = args.first?.object?.code.string,
               let input = WebBrowserKeyboardInput(rawValue: key) {
                self?.onKeyUp(input.keyboardInput)
            }
            return .undefined
        })
    }
    
    private func requestAnimationFrame() {
        _ = JSObject.global.requestAnimationFrame!(JSClosure { [weak self] args in
            guard let time = args.first?.number else { return .null }
            self?.update(time)
            return .undefined
        })
    }
    
    open func onKeyDown(_ key: KeyboardInput) {
        print("onKeyDown", key)
    }
    
    open func onKeyUp(_ key: KeyboardInput) {
        print("onKeyUp", key)
    }
    
    open func update(_ currentTime: Double) {
        requestAnimationFrame()
    }
}
