import SpriteKit

public protocol Node {
    func add(_ node: Node)
    func child(withName name: String) -> Node?
}

public protocol Renderer: Node {
    func setCameraPosition(_ point: CGPoint)
}

extension SKNode: Node {
    public func add(_ node: Node) {
        guard let castedNode = node as? SKNode else {
            return
        }
        addChild(castedNode)
    }

    public func child(withName name: String) -> Node? {
        let child: SKNode? = childNode(withName: name)
        return child as Node?
    }
}

extension SKScene: Renderer {
    public func setCameraPosition(_ point: CGPoint) {
        camera?.position = point
    }
}
