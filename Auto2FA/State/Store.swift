//
//  Store.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation

final class Store: ObservableObject {
  @Published private(set) var state: State
  private let reducer: Reducer
  private let environment: Environment

  init(
    state: State,
    reducer: @escaping Reducer,
    environment: Environment
  ) {
    self.state = state
    self.reducer = reducer
    self.environment = environment
  }

  func send(action: Action) {
    state = reducer(state, action, environment)
    #if DEBUG
      print(action)
      dump(state)
      print("\n")
    #endif
  }
}
