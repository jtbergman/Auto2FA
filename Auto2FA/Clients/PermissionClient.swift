//
//  PermissionClient.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation

final class PermissionClient {
  private let messages: MessageClient
  private let notifications: NotificationClient

  init(messageClient: MessageClient, notificationClient: NotificationClient) {
    self.messages = messageClient
    self.notifications = notificationClient
  }

  func monitorForPermissions() -> Task<Void, Never> {
    Task {
      while !Task.isCancelled {
        let messages = messages.canAccessMessagesDB()
        let notifications = await notifications
          .notificationAuthorizationStatus()
          .permissionIsGranted
        let authorized = messages && notifications
        await MainActor.run {
          store.send(
            action: .setMonitoringStatus(
              authorized ? .active : .needPermissions(messages: messages, notifications: notifications)
            )
          )
        }
        try? await Task.sleep(nanoseconds: permissionsGrantedPollFrequency)
      }
    }
  }
}
