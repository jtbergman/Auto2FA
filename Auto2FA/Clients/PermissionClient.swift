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

  func allPermissionsAreGranted() async -> Bool {
    let notificationsAreEnabled = await notifications
      .notificationAuthorizationStatus()
      .permissionIsGranted
    let messagesAreEnabled = messages.canAccessMessagesDB()
    return notificationsAreEnabled && messagesAreEnabled
  }

  func monitorForPermissions() -> Task<Void, Never> {
    Task {
      while !Task.isCancelled {
        let authorized = await allPermissionsAreGranted()
        await MainActor.run {
          store.send(action: .setMonitoringStatus(authorized ? .active : .needPermissions))
        }
        try? await Task.sleep(nanoseconds: permissionsGrantedPollFrequency)
      }
    }
  }
}
