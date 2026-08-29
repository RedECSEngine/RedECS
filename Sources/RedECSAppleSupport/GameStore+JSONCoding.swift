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

    convenience init(
        data: Data,
        environment: R.Environment,
        reducer: R,
        registration: GameRegistration<R.State, R.Action>
    ) throws {
        let state = try JSONDecoder.forOperations(registration).decode(R.State.self, from: data)
        self.init(
            state: state,
            environment: environment,
            reducer: reducer,
            registration: registration
        )
    }

    func saveState() throws -> Data {
        try JSONEncoder().encode(state)
    }
}

public extension JSONDecoder {
    static func forOperations<Root: GameState, Action: Equatable & Codable>(
        _ registration: GameRegistration<Root, Action>
    ) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.operationDecoding] = registration.decoderTable
        return decoder
    }
}
