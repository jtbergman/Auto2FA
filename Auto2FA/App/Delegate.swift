//
//  App.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/20/23.
//

import Foundation
import AppKit

let store = Store(
  state: State(),
  reducer: reducer(state:action:environment:),
  environment: Environment.live
)

final class Delegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    store.send(action: .initialize)
  }

  func applicationWillTerminate(_ notification: Notification) {
    store.send(action: .cleanup)
  }
}
