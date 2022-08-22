import RedECS
import RedECSUIComponents
import JavaScriptKit
/*
public struct WebHUDRenderingReducer<State: HUDRenderingCapable>: Reducer {
    public init() {}
    
    public func reduce(
        state: inout State,
        delta: Double,
        environment: WebRenderingEnvironment
    ) -> GameEffect<State, HUDAction<State.Formatter>> {
        state.hud.forEach { (id, hudComponent) in
            hudComponent.children.forEach { element in
                let id = id + String(element.id.hashValue)
                let node: JSObject
                if let stageNode = environment.renderer.stagedObjects[id] {
                    node = stageNode
                    switch element.type {
                    case .label(let label):
                        switch label.strategy {
                        case .fixed(let text):
                            node.text = text.jsValue
                        case .dynamic(let formatter):
                            let text = formatter.format(element.id, state)
                            node.text = text.jsValue
                        }
                    case .button: break
                    }
                } else {
                    switch element.type {
                    case .label(let label):
                        let textObj: JSObject
                        let options = JSObject.global.JSON.parse.function!("{\"fontSize\": 16, \"fill\": \(0xffffff)}")
                        switch label.strategy {
                        case .fixed(let text):
                            textObj = JSObject.global.PIXI.Text.function!.new(text.jsValue, options)
                        case .dynamic(let formatter):
                            let text = formatter.format(element.id, state)
                            textObj = JSObject.global.PIXI.Text.function!.new(text,options)
                        }
                        node = textObj
                    case .button(let button):
                        node = JSObject.global.PIXI.Graphics.function!.new()
                        _ = node.beginFill!(button.fillColor.hexValue)
                        switch button.shape {
                        case .polygon(let path):
                            let pointsArray = JSArray.constructor.new()
                            path.points.forEach {
                                _ = pointsArray.push?(
                                    JSObject.global.PIXI.Point.function!.new(
                                        $0.x.jsValue, $0.y.jsValue
                                    )
                                )
                            }
                            _ = node.drawShape!(JSObject.global.PIXI.Polygon.function!.new(pointsArray))
                        case .rect(let rect):
                            _ = node.drawRect!(
                                rect.origin.x.jsValue,
                                rect.origin.y.jsValue,
                                rect.size.width.jsValue,
                                rect.size.height.jsValue
                            )
                        case .circle(let circle):
                            _ = node.drawCircle!(circle.center.x.jsValue, circle.center.y.jsValue, circle.radius.jsValue)
                        }
                    }
                    
                    _ = environment.renderer.hudContainer.addChild!(node)
                    environment.renderer.stagedObjects[id] = node
                }
                
                node.x = (element.position.x).jsValue
                node.y = (element.position.y).jsValue
            }
        }
        return .none
    }
    
    public func reduce(
        state: inout State,
        action: HUDAction<State.Formatter>,
        environment: WebRenderingEnvironment
    ) -> GameEffect<State, HUDAction<State.Formatter>> {
        switch action {
        case .inputDown(let inputLocation):
            for (_, hudComponent) in state.hud {
                for element in hudComponent.children {
                    guard case let .button(button) = element.type else {
                        continue
                    }
                    var tapped = false
                    switch button.shape {
                    case .circle(let c):
                        let locatedCircle = c.offset(by: element.position)
                        if locatedCircle.contains(inputLocation) {
                            tapped = true
                        }
                    case .rect(let r):
                        let locatedRect = r.offset(by: element.position)
                        if locatedRect.contains(inputLocation) {
                            tapped = true
                        }
                    case .polygon(let poly):
                        let locatedRect = poly.calculateContainingRect().offset(by: element.position)
                        if locatedRect.contains(inputLocation) {
                            tapped = true
                        }
                    }
                    if tapped {
                        return .game(.onHUDElementInputDown(element.id))
                    }
                }
            }
        case .inputUp, .onHUDElementInputDown:
            break
        }
        return .none
    }
    
    public func reduce(
        state: inout State,
        entityEvent: EntityEvent,
        environment: WebRenderingEnvironment
    ) {
        guard case let .removed(id) = entityEvent else { return }
        guard let hudComponent = state.hud[id] else { return }
        hudComponent.children.forEach { element in
            let id = id + String(element.id.hashValue)
            guard let node = environment.renderer.stagedObjects[id] else { return }
            _ = environment.renderer.hudContainer.removeChild!(node)
            environment.renderer.stagedObjects[id] = nil
        }
    }
    
}
*/
