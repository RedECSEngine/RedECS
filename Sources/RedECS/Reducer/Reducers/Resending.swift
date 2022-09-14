public extension Reducer {
     func resending(
           _ transform: @escaping (Action) -> Action?
       ) -> AnyReducer<State, Action, Environment> {
           return AnyReducer(
            { _, _, _ in .none },
            { state, action, env in
                let effects = self.reduce(state: &state, action: action, environment: env)
                if let resultingAction = transform(action) {
                    return .many([
                        effects,
                        .game(resultingAction)
                    ])
                }
                return effects
            },
            { _,_,_ in .none }
           )
       }
}
