import JavaScriptKit
import RedECS
import Geometry

open class WebRenderer {
    public enum State {
        case loading
        case ready
    }
    
    public var state: State = .loading {
        didSet {
            stateChangeHandler?(oldValue, state)
        }
    }
    public var stateChangeHandler: ((State, State) -> Void)?
    
    public private(set) var size: Size
    private var app: JSObject!
    public var container: JSObject!
    public var stagedObjects: [EntityId: JSObject] = [:]
    
    public init(size: Size, stateChangeHandler: ((State, State) -> Void)? = nil) {
        self.size = size
        self.stateChangeHandler = stateChangeHandler
        embedRenderingLibrary()
    }
    
    private func embedRenderingLibrary() {
        let document = JSObject.global.document
        let scriptUrl = "https://cdnjs.cloudflare.com/ajax/libs/pixi.js/6.2.2/browser/pixi.js"
        let scriptEle = document.createElement("script")
        _ = scriptEle.setAttribute("src", scriptUrl)
        _ = scriptEle.addEventListener("load", JSClosure({ [weak self] _ in
            guard let self = self else { return .null }
            let options = JSObject.global.JSON.parse.function!("{\"width\": \(self.size.width), \"height\": \(self.size.height)}")
            self.app = JSObject.global.PIXI.Application.function!.new(options)
            self.container = JSObject.global.PIXI.Container.function!.new();
            self.container.position.y = self.size.height.jsValue
            self.container.scale.y = -1
            
            _ = self.app.stage.addChild(self.container)
            _ = document.body.appendChild(self.app.view)
            self.state = .ready
            return .null
        }))
        _ = document.body.appendChild(scriptEle)
    }
}
