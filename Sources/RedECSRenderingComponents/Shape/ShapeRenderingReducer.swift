import Foundation
import RedECS
import SpriteKit
import RedECSBasicComponents

public struct ShapeRenderingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout ShapeReducerContext,
        delta: Double,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<ShapeReducerContext, Never> {
        state.shape.forEach { (id, shape) in
            guard let position = state.position[id] else { return }
            
            if shape.node.parent == nil {
                shape.node.fillColor = .init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
                environment.renderer.add(shape.node)
            }
            
            shape.node.position = .init(x: position.point.x, y: position.point.y)
            
            if let transform = state.transform[id] {
                shape.node.zRotation = transform.rotate.degreesToRadians()
                shape.node.position.x += transform.translate.x
                shape.node.position.y += transform.translate.y
            }
        }
        return .none
    }
}
