import Geometry

extension Point {
    func rounded() -> Point {
        Point(x: x.rounded(), y: y.rounded())
    }
}
