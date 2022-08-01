import JavaScriptKit
import RedECS
import RedECSBasicComponents
import Geometry

open class WebBrowserWindow<State: GameState, Action: Equatable, Environment> {
    
    public private(set) var resourceManager: WebResourceManager
    public private(set) var renderer: WebRenderer
    public private(set) var store: GameStore<AnyReducer<State, Action, Environment>>!
    
    public private(set) var lastTime: Double?
    
    public required init(size: Size) {
        self.resourceManager = WebResourceManager(resourcePath: "Resources")
        self.renderer = WebRenderer(size: size, resourceLoader: resourceManager)
    }
    
    open func setStoreAndBegin(
        _ store: GameStore<AnyReducer<State, Action, Environment>>,
        preloading assets: [(String, ResourceType)],
        onReady: (() -> Void)? = nil
    ) {
        self.store = store
        resourceManager
            .preload(assets)
            .subscribe { [weak self] result in
                switch result {
                case .success:
                    self?.startWebRenderer()
                    onReady?()
                case .failure(let e):
                    print(e)
                    fatalError(e.localizedDescription)
                }
            }
    }
    
    /// If overriding, either call super or add listeners and request animation frame manually
    open func startWebRenderer() {
        addAllInputListeners()
        requestAnimationFrame()
    }
    
    public func addAllInputListeners() {
        addKeyboardListeners()
        addMouseListeners()
        addTouchListeners()
    }
    
    public func addKeyboardListeners() {
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
    
    public func addMouseListeners() {
        _ = renderer.canvasElement.addEventListener("mousedown", JSClosure { [weak self] args in
            guard let self = self, let event = args.first else { return .undefined }
            self.mouseDown(self.position(for: event, in: self.renderer.canvasElement))
            return .undefined
        }, false)
        
        _ = renderer.canvasElement.addEventListener("mousemove", JSClosure { [weak self] args in
            guard let self = self,  let event = args.first else { return .undefined }
            self.mouseMove(self.position(for: event, in: self.renderer.canvasElement))
            return .undefined
        }, false)
        
        _ = renderer.canvasElement.addEventListener("mouseup", JSClosure { [weak self] args in
            guard let self = self,  let event = args.first else { return .undefined }
            self.mouseUp(self.position(for: event, in: self.renderer.canvasElement))
            return .undefined
        }, false)
    }
    
    public func addTouchListeners() {
        _ = renderer.canvasElement.addEventListener("touchstart", JSClosure { [weak self] args in
            guard let self = self, let touchEvent = args.first else { return .undefined }
            let firstTouch = touchEvent.changedTouches[0]
            let x = firstTouch.pageX.number ?? 0
            let y = firstTouch.pageY.number ?? 0
            self.touchDown(Point(x: x, y: y))
            return .undefined
        }, false)
        
        _ = renderer.canvasElement.addEventListener("touchmove", JSClosure { [weak self] args in
            guard let self = self, let touchEvent = args.first else { return .undefined }
            let firstTouch = touchEvent.changedTouches[0]
            let x = firstTouch.pageX.number ?? 0
            let y = firstTouch.pageY.number ?? 0
            self.touchMove(Point(x: x, y: y))
            return .undefined
        }, false)
        
        _ = renderer.canvasElement.addEventListener("touchend", JSClosure { [weak self] args in
            guard let self = self, let touchEvent = args.first else { return .undefined }
            let firstTouch = touchEvent.changedTouches[0]
            let x = firstTouch.pageX.number ?? 0
            let y = firstTouch.pageY.number ?? 0
            self.touchUp(Point(x: x, y: y))
            return .undefined
        }, false)
    }
    
    private func position(for event: JSValue, in canvasElement: JSValue) -> Point {
        return position(
            x: event.clientX.number ?? 0,
            y: event.clientY.number ?? 0,
            in: canvasElement
        )
    }
    
    private func position(x: Double, y: Double, in canvasElement: JSValue) -> Point {
        let rect = canvasElement.getBoundingClientRect()
        return .init(
            x: x - (rect.left.number ?? 0),
            y: y - (rect.top.number ?? 0)
        )
    }
    
    /// This functions draws the enqueued work and calls update upon the next animation frame
    public func requestAnimationFrame() {
        _ = JSObject.global.requestAnimationFrame!(JSClosure { [weak self] args in
            guard let time = args.first?.number else { return .null }
            self?.renderer.clearTriangleQueue()
            self?.update(time)
            self?.renderer.draw()
            return .undefined
        })
    }
    
    public func update(_ currentTime: Double) {
        if let lastTime = lastTime {
            let delta = (currentTime - lastTime) / 100
            store.sendDelta(delta)
        }
        lastTime = currentTime
        requestAnimationFrame()
    }
    
    // MARK: - Keyboard
    
    open func onKeyDown(_ key: KeyboardInput) {
//        print("onKeyDown", key)
    }
    
    open func onKeyUp(_ key: KeyboardInput) {
//        print("onKeyUp", key)
    }
    
    // MARK: - Mouse
    
    open func mouseDown(_ location: Point) {
//        print("mouseDown", location)
    }
    
    open func mouseMove(_ location: Point) {
//        print("mouseMove", location)
    }
    
    open func mouseUp(_ location: Point) {
//        print("mouseMove", location)
    }
    
    // MARK: - Touch
    
    open func touchDown(_ location: Point) {
//        print("touchDown", location)
    }
    
    open func touchMove(_ location: Point) {
//        print("touchMove", location)
    }
    
    open func touchUp(_ location: Point) {
//        print("touchUp", location)
    }
    
}
