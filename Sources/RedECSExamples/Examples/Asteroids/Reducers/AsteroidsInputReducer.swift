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
        
        guard var ship = state.ship["ship"],
              let position = state.position[ship.entity],
              var momentum = state.momentum[ship.entity],
              var transform = state.transform[ship.entity] else {
                  fatalError("dafuk!?")
              }
        
        var gameEffects: [GameEffect<AsteroidsGameState, AsteroidsGameAction>] = []
        
        ship.bulletTimeout = max(0, ship.bulletTimeout - delta)
        
        if let keyboardInput = state.keyboardInput[ship.entity] {
            if keyboardInput.isAnyKeyPressed(in: [.upKey, .w]) {
                let y = cos(transform.rotate.degreesToRadians())
                let x = -sin(transform.rotate.degreesToRadians())
                let vector = Point(x: x, y: y) * (Double(delta) / 50)
                momentum.velocity.x += vector.x
                momentum.velocity.y += vector.y
                if momentum.velocity.distanceFrom(.zero) > 2 {
                    momentum.velocity.normalize(to: 2)
                }
            }
            if keyboardInput.isAnyKeyPressed(in: [.leftKey, .a]) {
                transform.rotate += 5
            }
            if keyboardInput.isAnyKeyPressed(in: [.rightKey, .d]) {
                transform.rotate -= 5
            }
            if keyboardInput.isKeyPressed(.space) && ship.bulletTimeout == 0 {
                let y = cos(transform.rotate.degreesToRadians())
                let x = -sin(transform.rotate.degreesToRadians())
                let bulletDirection = Point(x: x, y: y)
                let bulletVelocity = bulletDirection * 1.2
                gameEffects += [generateBulletCreationActions(
                    position: position.point.offsetBy(bulletDirection * 25),
                    velocity: momentum.velocity + bulletVelocity
                )]
                ship.bulletTimeout = 30
                print("entity count", state.entities.count)
            }
        }
        
        state.ship[ship.entity] = ship
        state.position[ship.entity] = position
        state.momentum[ship.entity] = momentum
        state.transform[ship.entity] = transform
        
        return .many(gameEffects)
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
        case .keyboardInput:
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
    let keyboard = KeyboardInputComponent(entity: shipId)
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

func generateAsteroidCreationActions(size: Int, point: Point) -> GameEffect<AsteroidsGameState, AsteroidsGameAction> {
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
