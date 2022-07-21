import RedECS
import Geometry
import GeometryAlgorithms

public struct SpriteRenderingReducer: Reducer {
    public init() {}
    
    public func reduce(
        state: inout SpriteRenderingContext,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<SpriteRenderingContext, Never> {
        state.sprite.forEach { (id, spriteComponent) in
            guard let transform = state.transform[id] else { return }
            do {
                guard let textureMap = environment.textures[spriteComponent.texture.textureId] else { return }
                
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
                    )
                )
                let bottomRenderTri = RenderTriangle(
                    triangle: Triangle(
                        a: Point(x: renderRect.maxX, y: renderRect.maxY),
                        b: Point(x: renderRect.maxX, y: renderRect.minY),
                        c: Point(x: renderRect.minX, y: renderRect.maxY)
                    ),
                    fragmentType: .texture(
                        spriteComponent.texture.textureId,
                        Triangle(
                            a: Point(x: textureRect.maxX, y: textureRect.maxY),
                            b: Point(x: textureRect.maxX, y: textureRect.minY),
                            c: Point(x: textureRect.minX, y: textureRect.maxY)
                        )
                    )
                )
                
                environment.renderer.enqueueTriangles([
                    topRenderTri,
                    bottomRenderTri
                ])
            } catch {
                print("⚠️ couldn't render shape", error)
            }
        }
        return .none
    }
    
    public func reduce(
        state: inout SpriteRenderingContext,
        entityEvent: EntityEvent,
        environment: RenderingEnvironment
    ) {

    }
}


