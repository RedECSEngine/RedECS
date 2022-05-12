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
            guard let position = state.position[id] else { return }
            
            let shape: JSObject
            if let shapeNode = environment.renderer.stagedObjects[id] {
                shape = shapeNode
            } else {
                shape = JSObject.global.PIXI.Graphics.function!.new()
                _ = shape.beginFill!(JSValue(0xff0000))
                switch shapeComponent.shape {
                case .polygon(let path):
                    let pointsArray = JSArray.constructor.new()
                    path.points.forEach {
                        _ = pointsArray.push?(
                            JSObject.global.PIXI.Point.function!.new(
                                $0.x.jsValue(), $0.y.jsValue()
                            )
                        )
                    }
                    _ = shape.drawShape!(JSObject.global.PIXI.Polygon.function!.new(pointsArray))
                case .rect(let rect):
                    _ = shape.drawRect!(
                        rect.origin.x.jsValue(),
                        rect.origin.y.jsValue(),
                        rect.size.width.jsValue(),
                        rect.size.height.jsValue()
                    )
                case .circle(let circle):
                    _ = shape.drawCircle!(circle.center.x.jsValue(), circle.center.y.jsValue(), circle.radius.jsValue())
                }
                
                _ = environment.renderer.container.addChild!(shape)
                environment.renderer.stagedObjects[id] = shape
            }
            
            let translate = state.transform[id]?.translate ?? .zero
            shape.x = (position.point.x + translate.x).jsValue()
            shape.y = (position.point.y + translate.y).jsValue()
            if let transform = state.transform[id] {
                shape.rotation = transform.rotate.degreesToRadians().jsValue()
            }
        }
        return .none
    }
    
    public func reduce(
        state: inout ShapeRenderingContext,
        entityEvent: EntityEvent,
        environment: WebRenderingEnvironment
    ) {
        guard case let .removed(id) = entityEvent,
              let shapeNode = environment.renderer.stagedObjects[id] else { return }
        _ = environment.renderer.container.removeChild!(shapeNode)
        environment.renderer.stagedObjects[id] = nil
    }
}


