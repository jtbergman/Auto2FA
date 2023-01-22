//
//  Store.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import AppKit
import Foundation
import RegexBuilder
import SQLite3
import UserNotifications

final class Store: ObservableObject {
  @Published private(set) var state: State
  private let reducer: Reducer

  init(state: State, reducer: @escaping Reducer = reducer(state:action:)) {
    self.state = state
    self.reducer = reducer
  }

  func send(action: Action) {
    state = reducer(state, action)
    print("Update: \(state)")
  }
}
