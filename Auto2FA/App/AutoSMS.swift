//
//  Auto2FA.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/20/23.
//

import SwiftUI

@main
struct Auto2FA: SwiftUI.App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @Environment(\.openWindow) var openWindow
  @State private var showConfigurationWindow = true

  var body: some Scene {
    MenuBarExtra {
      VStack {
        Button {
//          showWindow = true
          print("Show window")
        } label: {
//          Text("Monitoring for 2FA 🟢")
//          Text("Paused by User 🟡")
          Text("Permissions Missing 🔴 ")
        }

        Divider()

        Button("Report Issue") {
          guard let url = URL(string: "https://github.com/jtbergman/Auto2FA/issues/new?template=bug_report.md") else {
            return
          }
          NSWorkspace.shared.open(url)
        }
        Button("Quit") {
          NSApplication.shared.terminate(nil)
        }
      }
      .padding(.all)
    } label: {
      Image(systemName: "lock.rectangle.stack")
    }
  }
}
