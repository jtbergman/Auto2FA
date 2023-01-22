//
//  Environment.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation

struct Environment {
  let application: ApplicationClient
  let messages: MessageClient
  let notifications: NotificationClient
  let permissions: PermissionClient

  init(
    application: ApplicationClient,
    messages: MessageClient,
    notifications: NotificationClient,
    permissions: PermissionClient
  ) {
    self.application = application
    self.messages = messages
    self.notifications = notifications
    self.permissions = permissions
  }

  static var live: Environment = {
    let application = ApplicationClient()
    let notifications = NotificationClient()
    let messages = MessageClient(
      applicationClient: application,
      notificationClient: notifications
    )
    let permissions = PermissionClient(
      messageClient: messages,
      notificationClient: notifications
    )
    return Environment(
      application: application,
      messages: messages,
      notifications: notifications,
      permissions: permissions
    )
  }()
}
