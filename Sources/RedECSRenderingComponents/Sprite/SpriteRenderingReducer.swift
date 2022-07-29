import RedECS
import Geometry
import GeometryAlgorithms

public struct SpriteRenderingReducer: Reducer {
    public init() {}
    
    public func reduce(
        state: inout SpriteContext,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<SpriteContext, Never> {
        state.sprite.forEach { (id, spriteComponent) in
            guard let transform = state.transform[id] else { return }
            guard let textureMap = environment.resourceManager.getTexture(textureId: spriteComponent.texture.textureId) else {
                return }
            
            let textureRect: Rect
            if let frameId = spriteComponent.texture.frameId,
                let frameInfo = textureMap.frames.first(where: { $0.filename == frameId }) {
                textureRect = Rect(
                    x: frameInfo.frame.x,
                    y: frameInfo.frame.y,
                    width: frameInfo.frame.w,
                    height: frameInfo.frame.h
                )
            } else {
                let size = textureMap.meta.size
                textureRect = Rect(x: 0, y: 0, width: size.w, height: size.h)
            }
            
            let renderRect = Rect(center: transform.position, size: textureRect.size)
            let topRenderTri = RenderTriangle(
                triangle: Triangle(
                    a: Point(x: renderRect.minX, y: renderRect.maxY),
                    b: Point(x: renderRect.maxX, y: renderRect.minY),
                    c: Point(x: renderRect.maxX, y: renderRect.maxY)
                ),
                fragmentType: .texture(
                    spriteComponent.texture.textureId,
                    Triangle(
                        a: Point(x: textureRect.minX, y: textureRect.maxY),
                        b: Point(x: textureRect.maxX, y: textureRect.minY),
                        c: Point(x: textureRect.maxX, y: textureRect.maxY)
                    )
                ),
                zIndex: transform.zIndex
            )
            let bottomRenderTri = RenderTriangle(
                triangle: Triangle(
                    a: Point(x: renderRect.minX, y: renderRect.minY),
                    b: Point(x: renderRect.maxX, y: renderRect.minY),
                    c: Point(x: renderRect.minX, y: renderRect.maxY)
                ),
                fragmentType: .texture(
                    spriteComponent.texture.textureId,
                    Triangle(
                        a: Point(x: textureRect.minX, y: textureRect.minY),
                        b: Point(x: textureRect.maxX, y: textureRect.minY),
                        c: Point(x: textureRect.minX, y: textureRect.maxY)
                    )
                ),
                zIndex: transform.zIndex
            )
            
            environment.renderer.enqueueTriangles([
                bottomRenderTri,
                topRenderTri,
            ])
        }
        return .none
    }
    
    public func reduce(
        state: inout SpriteContext,
        entityEvent: EntityEvent,
        environment: RenderingEnvironment
    ) {

    }
}


