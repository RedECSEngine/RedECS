import Foundation
import RedECS

public extension GameStore {
    
    convenience init(
        data: Data,
        environment: R.Environment,
        reducer: R,
        registeredComponentTypes: Set<RegisteredComponentType<R.State>>
    ) throws {
        let state = try JSONDecoder().decode(R.State.self, from: data)
        self.init(
            state: state,
            environment: environment,
            reducer: reducer,
            registeredComponentTypes: registeredComponentTypes
        )
    }

    func saveState() throws -> Data {
        try JSONEncoder().encode(state)
    }
}
