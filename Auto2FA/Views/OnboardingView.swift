//
//  OnboardingView.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/20/23.
//

import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject var store: Store
  let permitted = "checkmark.circle.fill"

  var fullDiskAccessAuthorized: Bool {
    switch store.state.monitoringStatus {
    case .needPermissions(messages: let value, notifications: _):
      return value
    default:
      return true
    }
  }

  var pushNotificationsAuthorized: Bool {
    switch store.state.monitoringStatus {
    case .needPermissions(messages: _, notifications: let value):
      return value
    default:
      return true
    }
  }

  var messageIcon: String {
    fullDiskAccessAuthorized ? permitted : "message"
  }

  var notificationIcon: String {
    pushNotificationsAuthorized ? permitted : "bell.badge"
  }

  var body: some View {
    VStack {
      Text("Getting Started")
        .font(.system(.largeTitle, design: .rounded))
        .fontWeight(.heavy)
      HStack {
        VStack(spacing: 8) {
          Image(systemName: messageIcon)
            .imageScale(.large)
            .foregroundColor(fullDiskAccessAuthorized ? .green :.accentColor)
          Text("Auto2FA needs access to iMessages. Messages never leave your device.")
            .multilineTextAlignment(.center)
            .frame(maxWidth: 200)
          Button {
            store.send(action: .openFullDiskAccessSetting)
          } label: {
            Text(fullDiskAccessAuthorized ? "Completed" : "Grant Access")
          }
          .disabled(fullDiskAccessAuthorized)
        }.frame(maxWidth: .infinity)
        VStack(spacing: 8) {
          Image(systemName: notificationIcon)
            .imageScale(.large)
            .foregroundColor(pushNotificationsAuthorized ? .green :.accentColor)
          Text("Allow Auto2FA to send push notifications when 2FA codes are available.")
            .frame(maxWidth: 200)
            .multilineTextAlignment(.center)
          Button {
            store.send(action: .pushNotificationsRequestAccess)
          } label: {
            Text(pushNotificationsAuthorized ? "Completed" : "Enable Notifications")
          }
          .disabled(pushNotificationsAuthorized)
        }.frame(maxWidth: .infinity)
      }
      .padding()
      Text("For security reasons, Auto2FA does not use any third-party code.")
        .font(.system(.caption, design: .rounded))
        .foregroundColor(.gray)
      Text("All push notifications will be cleared automatically.")
        .font(.system(.caption, design: .rounded))
        .foregroundColor(.gray)
      Text("[View Source Code](https://github.com/jtbergman/Auto2FA)")
        .font(.system(.caption, design: .rounded))
        .opacity(0.8)
    }
    .padding(.all)
    .frame(minWidth: 500, minHeight: 300)
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
