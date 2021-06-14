//
//  Reducer.swift
//  
//
//  Created by Kyle Newsome on 2021-06-11.
//

import Foundation

public protocol Reducer {
    associatedtype State: GameState
    associatedtype Action
    associatedtype Environment: GameEnvironment
    
    func reduce(state: inout State, action: Action, environment: Environment) -> GameEffect<State, Action>
}
