//
//  NotificationClient.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation
import UserNotifications

final class NotificationClient {
  private let notifications = UNUserNotificationCenter.current()

  func notificationAuthorizationStatus() async -> UNAuthorizationStatus {
    await withCheckedContinuation { continuation in
      notifications.getNotificationSettings { settings in
        continuation.resume(with: .success(settings.authorizationStatus))
      }
    }
  }

  func requestAuthorization() {
    Task {
      try? await notifications.requestAuthorization(options: [.alert, .sound])
    }
  }

  func removeAllDeliveredNotifications() {
    notifications.removeAllDeliveredNotifications()
  }

  func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
    notifications.removeDeliveredNotifications(withIdentifiers: identifiers)
  }

  func sendNotification(for securityCode: SecurityCode) {
    Task {
      guard (await notificationAuthorizationStatus().permissionIsGranted) else {
        return
      }
      let content = UNMutableNotificationContent()
      content.title = "Copied to Clipboard"
      content.body = "From messages"
      content.interruptionLevel = .timeSensitive

      let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
      )

      try? await notifications.add(request)
      try? await Task.sleep(nanoseconds: localNotificationShowDuration)
      removeDeliveredNotifications(withIdentifiers: [request.identifier])
    }
  }
}
