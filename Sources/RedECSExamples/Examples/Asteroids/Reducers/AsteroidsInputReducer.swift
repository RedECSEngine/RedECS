import Foundation
import SpriteKit
import RedECS
import RedECSBasicComponents
import RedECSRenderingComponents
import Geometry

public struct AsteroidsInputReducer: Reducer {
    public func reduce(
        state: inout AsteroidsGameState,
        delta: Double,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
        state.lastDelta = delta
        state.ship[ship.entity]?.bulletTimeout = max(0, ship.bulletTimeout - delta)
        return .none
    }
    
    public func reduce(
        state: inout AsteroidsGameState,
        action: AsteroidsGameAction,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
        switch action {
        case .newGame:
            return .many([
                generateShipCreationActions(),
                generateAsteroidCreationActions(size: 4, point: .init(x: 300, y: 300))
            ])
        case .propelForward:
            guard let ship = state.ship["ship"],
                  var momentum = state.momentum[ship.entity],
                  let transform = state.transform[ship.entity] else {
                      fatalError("dafuk!?")
                  }
            let y = cos(transform.rotate.degreesToRadians())
            let x = -sin(transform.rotate.degreesToRadians())
            let vector = Point(x: x, y: y) * (Double(state.lastDelta) / 50)
            momentum.velocity.x += vector.x
            momentum.velocity.y += vector.y
            if momentum.velocity.distanceFrom(.zero) > 2 {
                momentum.velocity.normalize(to: 2)
            }
            state.momentum[ship.entity] = momentum
            return .none
        case .rotateLeft:
            guard let ship = state.ship["ship"],
                  var transform = state.transform[ship.entity] else {
                      fatalError("dafuk!?")
                  }
            transform.rotate += 5
            state.transform[ship.entity] = transform
            return .none
        case .rotateRight:
            guard let ship = state.ship["ship"],
                  var transform = state.transform[ship.entity] else {
                      fatalError("dafuk!?")
                  }
            transform.rotate -= 5
            state.transform[ship.entity] = transform
            return .none
        case .fireBullet:
            guard var ship = state.ship["ship"],
                  let position = state.position[ship.entity],
                  let momentum = state.momentum[ship.entity],
                  let transform = state.transform[ship.entity] else {
                      fatalError("dafuk!?")
                  }
            
            guard ship.bulletTimeout == 0 else { return .none }
            
            let y = cos(transform.rotate.degreesToRadians())
            let x = -sin(transform.rotate.degreesToRadians())
            let bulletDirection = Point(x: x, y: y)
            let bulletVelocity = bulletDirection * 1.2
            ship.bulletTimeout = 30
            
            state.ship[ship.entity] = ship
            return .many([generateBulletCreationActions(
                position: position.point.offsetBy(bulletDirection * 25),
                velocity: momentum.velocity + bulletVelocity
            )])
        default:
            return .none
        }
    }
}

func generateShipCreationActions() -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
    let shipId: EntityId = "ship"
    let ship = ShipComponent(entity: shipId)
    let shape = ShapeComponent(entity: shipId, shape: .polygon(ship.path))
    let position = PositionComponent(entity: shipId, point: .init(x: 100, y: 100))
    let movement = MovementComponent(entity: shipId, velocity: .zero, travelSpeed: 1)
    let transform = TransformComponent(entity: shipId)
    let momentum = MomentumComponent(entity: shipId, velocity: .zero)
    let keyboard = KeyboardInputComponent<AsteroidsGameAction>(
        entity: shipId,
        keyMap: [
            ([.a, .leftKey], .rotateLeft),
            ([.d, .rightKey], .rotateRight),
            ([.space], .fireBullet),
            ([.w, .upKey], .propelForward),
        ]
    )
    return .many([
        .system(.addEntity(shipId, [])),
        .system(.addComponent(ship, into: \.ship)),
        .system(.addComponent(shape, into: \.shape)),
        .system(.addComponent(position, into: \.position)),
        .system(.addComponent(movement, into: \.movement)),
        .system(.addComponent(transform, into: \.transform)),
        .system(.addComponent(momentum, into: \.momentum)),
        .system(.addComponent(keyboard, into: \.keyboardInput))
    ])
}

func generateAsteroidCreationActions(size: Int32, point: Point) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
    let asteroidId: EntityId = UUID().uuidString
    let asteroid = AsteroidComponent(entity: asteroidId, size: size, path: nil)
    let shape = ShapeComponent(entity: asteroidId, shape: .polygon(asteroid.path))
    let position = PositionComponent(entity: asteroidId, point: point)
    let movement = MovementComponent(entity: asteroidId, velocity: .zero, travelSpeed: 1)
    let transform = TransformComponent(entity: asteroidId)
    let momentum = MomentumComponent(
        entity: asteroidId,
        velocity: .init(x: .random(in: 0...1), y: .random(in: 0...1))
    )
    return .many([
        .system(.addEntity(asteroidId, ["asteroid"])),
        .system(.addComponent(asteroid, into: \.asteroid)),
        .system(.addComponent(shape, into: \.shape)),
        .system(.addComponent(position, into: \.position)),
        .system(.addComponent(movement, into: \.movement)),
        .system(.addComponent(transform, into: \.transform)),
        .system(.addComponent(momentum, into: \.momentum))
    ])
}

func generateBulletCreationActions(position: Point, velocity: Point) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
    let bulletId: EntityId = UUID().uuidString
    let shape = ShapeComponent(entity: bulletId, shape: .circle(.init(radius: 2)))
    let position = PositionComponent(entity: bulletId, point: position)
    let movement = MovementComponent(entity: bulletId, velocity: .zero, travelSpeed: 1)
    let momentum = MomentumComponent(entity: bulletId, velocity: velocity)
    return .many([
        .system(.addEntity(bulletId, ["bullet"])),
        .system(.addComponent(shape, into: \.shape)),
        .system(.addComponent(position, into: \.position)),
        .system(.addComponent(movement, into: \.movement)),
        .system(.addComponent(momentum, into: \.momentum))
    ])
}
