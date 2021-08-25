import Foundation

public struct Promise<T, E: Error> {
    public typealias ResolutionBlock = (Result<T, E>) -> Void
    public typealias ObserverCreationBlock = (@escaping ResolutionBlock) -> Void

    private var observer: (@escaping ResolutionBlock) -> Void

    public init(observer: @escaping ObserverCreationBlock) {
        self.observer = observer
    }

    public func subscribe(_ resolve: @escaping ResolutionBlock) -> Void {
        observer { result in
            resolve(result)
        }
    }
        
    public func map<A>(_ transform: @escaping (T) -> A) -> Promise<A, E> {
        return .init { resolve in
            self.subscribe { resolve($0.map(transform)) }
        }
    }

    public func recoverError(_ transform: @escaping (E) -> T) -> Promise<T, Never> {
        return .init { resolve in
            self.subscribe { result in
                resolve(result.flatMapError({ error in
                    return .success(transform(error))
                }))
            }
        }
    }
}

public extension Promise where E == Never {
    static func just(_ value: T) -> Promise<T, Never> {
        Promise(observer: { resolve in resolve(.success(value)) })
    }

    func onDone(_ completion: @escaping (T) -> Void) {
        self.subscribe { result in
            switch result {
            case .success(let value):
                completion(value)
            }
        }
    }
}
