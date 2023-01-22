//
//  MenuBarView.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation
import SwiftUI

struct MenuBarView: View {
  @EnvironmentObject var store: Store

  var body: some View {
    VStack {
      Button {
        store.send(action: .selectMenuStatusItem)
      } label: {
        switch store.state.monitoringStatus {
        case .active:
          Text("Monitoring for 2FA 🟢")
        case .paused:
          Text("Paused by User 🟡")
        case .needPermissions:
          Text("Permissions Missing 🔴 ")
        }
      }
      Divider()
      Button("Report Issue") {
        store.send(action: .reportIssue)
      }
      Button("Quit") {
        store.send(action: .quit)
      }
    }
    .padding(.all)
  }
}
