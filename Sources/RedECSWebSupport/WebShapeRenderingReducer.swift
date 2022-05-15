import RedECS
import RedECSRenderingComponents
import JavaScriptKit

public struct WebShapeRenderingReducer: Reducer {
    public init() {}
    
    public func reduce(
        state: inout ShapeRenderingContext,
        delta: Double,
        environment: WebRenderingEnvironment
    ) -> GameEffect<ShapeRenderingContext, Never> {
        state.shape.forEach { (id, shapeComponent) in
            guard let transform = state.transform[id] else { return }
            
            if shapeComponent.needsRedraw {
                removeStagedObjectIfNeeded(id, environment: environment)
                state.shape[id]?.needsRedraw = false
            }
            
            let shape: JSObject
            if let shapeNode = environment.renderer.stagedObjects[id] {
                shape = shapeNode
            } else {
                shape = JSObject.global.PIXI.Graphics.function!.new()
                _ = shape.beginFill!(shapeComponent.fillColor.hexValue)
                switch shapeComponent.shape {
                case .polygon(let path):
                    let pointsArray = JSArray.constructor.new()
                    path.points.forEach {
                        _ = pointsArray.push?(
                            JSObject.global.PIXI.Point.function!.new(
                                $0.x.jsValue, $0.y.jsValue
                            )
                        )
                    }
                    _ = shape.drawShape!(JSObject.global.PIXI.Polygon.function!.new(pointsArray))
                case .rect(let rect):
                    _ = shape.drawRect!(
                        rect.origin.x.jsValue,
                        rect.origin.y.jsValue,
                        rect.size.width.jsValue,
                        rect.size.height.jsValue
                    )
                case .circle(let circle):
                    _ = shape.drawCircle!(circle.center.x.jsValue, circle.center.y.jsValue, circle.radius.jsValue)
                }
                
                _ = environment.renderer.gameObjectContainer.addChild!(shape)
                environment.renderer.stagedObjects[id] = shape
            }
            
            shape.x = (transform.position.x).jsValue
            shape.y = (transform.position.y).jsValue
            
            if let transform = state.transform[id] {
                shape.rotation = transform.rotate.degreesToRadians().jsValue
            }
        }
        return .none
    }
    
    public func reduce(
        state: inout ShapeRenderingContext,
        entityEvent: EntityEvent,
        environment: WebRenderingEnvironment
    ) {
        guard case let .removed(id) = entityEvent else { return }
        removeStagedObjectIfNeeded(id, environment: environment)
    }
    
    public func removeStagedObjectIfNeeded(_ id: EntityId, environment: WebRenderingEnvironment) {
        guard let shapeNode = environment.renderer.stagedObjects[id] else { return }
        _ = environment.renderer.gameObjectContainer.removeChild!(shapeNode)
        environment.renderer.stagedObjects[id] = nil
    }
}


