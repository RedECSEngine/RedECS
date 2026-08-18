import Geometry

public extension LerpKey where Value == Point {
    static var position: Self { .init("TransformComponent.position") }
    static var scale: Self { .init("TransformComponent.scale") }
}

public extension LerpKey where Value == Double {
    static var rotation: Self { .init("TransformComponent.rotate") }
    static var opacity: Self { .init("SpriteComponent.opacity") }
}

public extension LerpKey where Value == Int {
    static var zIndex: Self { .init("TransformComponent.zIndex") }
}

public extension LerpKey where Value == Color {
    static var fillColor: Self { .init("SpriteComponent.fillColor") }
}

extension TransformComponent: OperationSupportingComponent {
    public static func bindOperationSupport<B: ComponentBinder>(_ binder: inout B) where B.Component == Self {
        binder.value(.position, \.position)
        binder.value(.scale, \.scale)
        binder.value(.rotation, \.rotate)
        binder.value(.zIndex, \.zIndex)
    }
}

extension SpriteComponent: OperationSupportingComponent {
    public static func bindOperationSupport<B: ComponentBinder>(_ binder: inout B) where B.Component == Self {
        binder.value(.opacity, \.opacity)
        binder.value(.fillColor, \.fillColor)
    }
}
