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
    public var gameObjectContainer: JSObject!
    public var hudContainer: JSObject!
    public private(set) var canvasElement: JSValue!
    
    public var stagedObjects: [EntityId: JSObject] = [:]
    
    public init(size: Size, stateChangeHandler: ((State, State) -> Void)? = nil) {
        self.size = size
        self.stateChangeHandler = stateChangeHandler
        embedRenderingLibrary()
    }
    
    private func embedRenderingLibrary() {
        let document = JSObject.global.document
        let scriptUrl = "https://cdnjs.cloudflare.com/ajax/libs/pixi.js/6.2.2/browser/pixi.js"
        self.canvasElement = document.createElement("canvas")
        canvasElement.id = "redecs-canvas"
        let scriptEle = document.createElement("script")
        _ = scriptEle.setAttribute("src", scriptUrl)
        _ = scriptEle.addEventListener("load", JSClosure({ [weak self] _ in
            guard let self = self else { return .null }
            var options = JSObject.global.JSON.parse.function!("{\"width\": \(self.size.width), \"height\": \(self.size.height)}")
            options.view = self.canvasElement
            
            self.app = JSObject.global.PIXI.Application.function!.new(options)
            self.gameObjectContainer = JSObject.global.PIXI.Container.function!.new();
            self.gameObjectContainer.position.y = self.size.height.jsValue
            self.gameObjectContainer.scale.y = -1
            _ = self.app.stage.addChild(self.gameObjectContainer)
            
            self.hudContainer = JSObject.global.PIXI.Container.function!.new();
            _ = self.app.stage.addChild(self.hudContainer)
            
            _ = document.body.appendChild(self.app.view)
            self.state = .ready
            return .null
        }))
        
        _ = document.body.appendChild(canvasElement)
        _ = document.body.appendChild(scriptEle)
    }
}
