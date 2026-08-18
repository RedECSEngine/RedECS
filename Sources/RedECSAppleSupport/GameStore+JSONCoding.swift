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

    /// Restores a saved state, including any operations that were mid-flight.
    ///
    /// The registration is what makes decoding possible: operations added by game
    /// code are erased in the save file down to a type tag, and only the
    /// registration knows which concrete type each tag names.
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
    /// A decoder that can resolve the operations a registration provides.
    static func forOperations<Root: GameState, Action: Equatable & Codable>(
        _ registration: GameRegistration<Root, Action>
    ) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.operationDecoding] = registration.decoderTable
        return decoder
    }
}
