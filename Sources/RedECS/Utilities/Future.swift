public struct Future<T, E: Error> {
    public typealias ResolutionBlock = (Result<T, E>) -> Void
    public typealias ObserverCreationBlock = (@escaping ResolutionBlock) -> Void

    private var observer: (@escaping ResolutionBlock) -> Void

    public init(observer: @escaping ObserverCreationBlock) {
        self.observer = observer
    }

    public func subscribe(_ resolve: @escaping ResolutionBlock) {
        observer { result in
            resolve(result)
        }
    }
        
    public func map<A>(_ transform: @escaping (T) -> A) -> Future<A, E> {
        return .init { resolve in
            self.subscribe { resolve($0.map(transform)) }
        }
    }
    
    public func readValue(_ readClosure: @escaping (Result<T, E>) -> Void) -> Future<T, E> {
        return .init { resolve in
            self.subscribe {
                readClosure($0)
                resolve($0)
            }
        }
    }
    
    public func flatMap<A>(_ transform: @escaping (T) -> Future<A, E>) -> Future<A, E> {
        return .init { resolve in
            self.subscribe { result in
                switch result {
                case .success(let value):
                    transform(value).subscribe(resolve)
                case .failure(let e):
                    resolve(.failure(e))
                }
            }
        }
    }

    public func recoverError(_ transform: @escaping (E) -> T) -> Future<T, Never> {
        return .init { resolve in
            self.subscribe { result in
                resolve(result.flatMapError({ error in
                    return .success(transform(error))
                }))
            }
        }
    }
    
}

public extension Future {
    static func zip<A, B, E: Error>(_ a: Future<A, E>, _ b: Future<B, E>) -> Future<(A, B), E> {
        Future<(A, B), E> { resolver in
            var valueA: A?
            var valueB: B?
            
            func resolveIfComplete() {
                if let valueA = valueA, let valueB = valueB {
                    resolver(.success((valueA, valueB)))
                }
            }
            
            a.subscribe { result in
                switch result {
                case .success(let aValue):
                    valueA = aValue
                    resolveIfComplete()
                case .failure(let e):
                    resolver(.failure(e))
                }
            }
            b.subscribe { result in
                switch result {
                case .success(let bValue):
                    valueB = bValue
                    resolveIfComplete()
                case .failure(let e):
                    resolver(.failure(e))
                }
            }
        }
    }
    
    static func zip<A, B, C, E: Error>(_ a: Future<A, E>, _ b: Future<B, E>, _ c: Future<C, E>) -> Future<(A, B, C), E> {
        Future<(A, B, C), E> { resolver in
            zip(zip(a, b), c)
                .subscribe { result in
                    switch result {
                    case .success(let ab_c):
                        resolver(.success((ab_c.0.0, ab_c.0.1, ab_c.1)))
                    case .failure(let error):
                        resolver(.failure(error))
                    }
                }
        }
    }
    
    static func zip<A, E: Error>(_ all: [Future<A, E>]) -> Future<[A], E> {
        if all.isEmpty {
            return .just([])
        }
        return Future<[A], E> { resolver in
            var cumulative: [A] = []
            var cumulativeCount = 0
            cumulative.reserveCapacity(all.count)
            
            func resolveIfComplete() {
                if cumulativeCount == all.count {
                    resolver(.success(cumulative))
                }
            }
            
            all.enumerated().forEach { i, future in
                future.subscribe { result in
                    switch result {
                    case .success(let value):
                        cumulative.insert(value, at: i)
                        cumulativeCount += 1
                        resolveIfComplete()
                    case .failure(let e):
                        resolver(.failure(e))
                    }
                }
            }
        }
    }
    
    func toVoid() -> Future<Void, E> {
        map { _ in () }
    }
    
    static func just(_ value: T) -> Future<T, E> {
        Future(observer: { resolve in resolve(.success(value)) })
    }
    
    static func fail(_ error: E) -> Future<T, E> {
        Future(observer: { resolve in resolve(.failure(error)) })
    }
}

public extension Future where E == Never {
    func onDone(_ completion: @escaping (T) -> Void) {
        self.subscribe { result in
            switch result {
            case .success(let value):
                completion(value)
            }
        }
    }
}
