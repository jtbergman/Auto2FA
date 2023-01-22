//
//  App.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/20/23.
//

import SwiftUI

@main
struct App: SwiftUI.App {
  @NSApplicationDelegateAdaptor(Delegate.self) var delegate

  var body: some Scene {
    MenuBarExtra {
      MenuBarView().environmentObject(store)
    } label: {
      Image(systemName: "lock.rectangle.stack")
    }
  }
}
