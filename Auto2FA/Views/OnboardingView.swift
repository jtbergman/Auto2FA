//
//  OnboardingView.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/20/23.
//

import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject var store: Store

  var body: some View {
    VStack {
      Text("Getting Started")
        .font(.system(.largeTitle, design: .rounded))
        .fontWeight(.heavy)
      HStack {
        VStack(spacing: 8) {
          Image(systemName: "message")
            .imageScale(.large)
            .foregroundColor(.accentColor)
          Text("Auto2FA needs access to iMessages. Messages never leave your device.")
            .multilineTextAlignment(.center)
            .frame(maxWidth: 200)
          Button {
            store.send(action: .openFullDiskAccessSetting)
          } label: {
            Text("Grant Access")
          }
        }.frame(maxWidth: .infinity)
        VStack(spacing: 8) {
          Image(systemName: "bell.badge")
            .imageScale(.large)
            .foregroundColor(.accentColor)
          Text("Allow Auto2FA to send push notifications when 2FA codes are available.")
            .frame(maxWidth: 200)
            .multilineTextAlignment(.center)
          Button {
            store.send(action: .pushNotificationsRequestAccess)
          } label: {
            Text("Enable Notifications")
          }
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
