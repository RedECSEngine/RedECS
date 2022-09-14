import RedECS

public struct ResourceLoadingReducer<S: GameState>: Reducer {
    public typealias State = S
    public typealias Action = ResourceLoadingAction
    public typealias Environment = RenderingEnvironment
    
    public init() {}
    
    public func reduce(state: inout State, delta: Double, environment: Environment) -> GameEffect<State, Action> {
       return .none
    }
    
    public func reduce(state: inout State, action: Action, environment: Environment) -> GameEffect<State, Action> {
        switch action {
        case .load(let groupName, let resources):
            print("⚙️ Load start, group: ", groupName)
            let future: Future<GameEffect<State, Action>, Never> = environment.resourceManager
                .preload(resources)
                .map({ _ in
                    return .game(.loadComplete(groupName: groupName))
                })
                .recoverError({ error in
                    .game(.loadingError(groupName: groupName, error: String(describing: error)))
                })
            return .deferred(future)
        case .loadingError(let groupName, let error):
            print("💥 Preload Error :: \(groupName) :: \(String(describing: error))")
            assertionFailure()
            return .none
        case .loadComplete(let groupName):
            print("✅ Load complete, group: ", groupName)
            return .none
        }
    }
}
