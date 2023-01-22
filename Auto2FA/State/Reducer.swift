//
//  Reducer.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import AppKit
import Foundation
import RegexBuilder
import UserNotifications
import SQLite3

typealias Reducer = (State, Action, Environment) -> State

func reducer(state: State, action: Action, environment: Environment) -> State {
  switch action {
  case .cleanup:
    environment.notifications.removeAllDeliveredNotifications()
    return state

  case .initialize:
    environment.notifications.removeAllDeliveredNotifications()
    var state = state
    state.monitoringTask = monitorForPermissions()
    return state

  case .openFullDiskAccessSetting:
    environment.application.open(URL(string: state.fullDiskAccessSettingURL))
    return state

  case .pushNotificationsRequestAccess:
    environment.notifications.requestAuthorization()
    return state

  case .reportIssue:
    environment.application.open(URL(string: state.reportIssueURL))
    return state

  case .selectMenuStatusItem:
    return reducer(
      state: state,
      action: .setMonitoringStatus(state.monitoringStatus.toggled()),
      environment: environment
    )

  case .setMonitoringStatus(let status):
    var state = state
    switch status {
    case .active:
      state.onboardingWindow = nil
      state.monitoringTask = monitorForMessages()
    case .needPermissions:
      state.onboardingWindow = showOnboardingWindow()
      state.monitoringTask = monitorForPermissions()
    case .paused:
      state.onboardingWindow = nil
      state.monitoringTask = nil
    }
    state.monitoringStatus = status
    return state

  case .quit:
    environment.application.terminate()
    return state
  }
}


// MARK: Helpers

/// Shows an onboarding window in the center of the screen and brings it in front of all other apps
func showOnboardingWindow() -> NSWindow {
  let window = OnboardingWindow()
  window.screen?.visibleFrame ?> { frame in
    let offsetX = window.frame.width / 2
    let offsetY = window.frame.height / 2
    let initialPosition = CGPoint(
      x: frame.midX - offsetX,
      y: frame.midY - offsetY
    )
    window.setFrameOrigin(initialPosition)
  }
  window.makeKeyAndOrderFront(nil)
  NSApp.activate(ignoringOtherApps: true)
  return window
}

func askForLocalNotifications() async -> Bool {
  let notifications = UNUserNotificationCenter.current()
  let approved = try? await notifications.requestAuthorization(options: [.alert, .sound])
  return approved ?? false
}

func notificationAuthorizationStatus() async -> UNAuthorizationStatus {
  await withCheckedContinuation { continuation in
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      continuation.resume(with: .success(settings.authorizationStatus))
    }
  }
}

func canAccessMessagesDB() -> Bool {
  let home = FileManager.default.homeDirectoryForCurrentUser
  let messages = home.appending(path: "Library/Messages/chat.db")
  return FileManager.default.isReadableFile(atPath: messages.path())
}

func extractSecurityCodes(_ messages: [Message]) -> [SecurityCode] {
  let regex = Regex {
    Capture {
      OneOrMore(.digit)
    }
  }
  var codes = [SecurityCode]()
  for message in messages {
    message.text.firstMatch(of: regex) ?> { match in
      let code = String(match.output.0)
      codes.append(SecurityCode(id: message.id, code: code))
    }
  }
  print(codes)
  return codes
}

func sendNotificationForOTP(_ otp: String) {
  let notifications = UNUserNotificationCenter.current()
  notifications.getNotificationSettings { settings in
    switch settings.authorizationStatus {
    case .authorized, .provisional:
      let content = UNMutableNotificationContent()
      content.title = "Copied to Clipboard"
      content.body = "From messages"
      let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
      )
      notifications.add(request)
      Task {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
      }
    default:
      break
    }
  }
}

func copyToClipboard(_ otp: String) {
  NSPasteboard.general.clearContents()
  NSPasteboard.general.setString(otp, forType: .string)
}

func observeMessagesDB() -> [Message] {
  let home = FileManager.default.homeDirectoryForCurrentUser
  let messages = home.appending(path: "Library/Messages/chat.db")
  var db: OpaquePointer!
  guard sqlite3_open(messages.path(), &db) == SQLITE_OK else {
    return []
  }

  // Create a date for all messages in the last 3 minutes in the expected format
  guard let date = Calendar.current.date(byAdding: .minute, value: -120, to: .now) else {
    print("Failed to create date")
    return []
  }
  let dateInMessageTime = Int(date.timeIntervalSinceReferenceDate) * 1_000_000_000

  // Create the raw SQL query statement using ? for our date parameter
  let query = """
    SELECT guid, text, is_from_me, date, service FROM message
      WHERE
        text IS NOT NULL
      AND
        is_from_me=false
      AND
        date >= ?
      AND
        service="SMS"
      ORDER BY date DESC
      LIMIT
        5;
    """

  // Create a reusable prepared statement
  var preparedQuery: OpaquePointer?
  guard sqlite3_prepare_v2(db, query, -1, &preparedQuery, nil) == SQLITE_OK else {
    print("Failed to prepare query")
    return []
  }

  // Bind the reference date to the preparedQuery (nb: parameters are indexed from 1)
  guard sqlite3_bind_int64(preparedQuery, 1, sqlite3_int64(dateInMessageTime)) == SQLITE_OK else {
    print("Failed to bind")
    return []
  }

  // Get all rows associated with the query
  var rows = [Message]()
  while sqlite3_step(preparedQuery) == SQLITE_ROW {
    let guid = String(cString: sqlite3_column_text(preparedQuery, 0))
    let text = String(cString: sqlite3_column_text(preparedQuery, 1))
    rows.append(Message(id: guid, text: text))
  }

  return rows
}

func monitorForMessages() -> Task<Void, Never> {
  Task {
    while !Task.isCancelled {
      let messages = observeMessagesDB().filter { !sent.contains($0.id) }
      extractSecurityCodes(messages).first ?> { code in
        sent.insert(code.id)
        copyToClipboard(code.code)
        sendNotificationForOTP(code.code)
      }
      try? await Task.sleep(nanoseconds: 5_000_000_000)
    }
  }
}

func monitorForPermissions() -> Task<Void, Never> {
  Task {
    while !Task.isCancelled {
      let authorized = await checkPermissions()
      if authorized {
        await MainActor.run {
          store.send(action: .setMonitoringStatus(authorized ? .active : .needPermissions))
        }
      }
      try? await Task.sleep(nanoseconds: 3_000_000_000)
    }
  }
}

func checkPermissions() async -> Bool {
  let notificationsAreEnabled = (await notificationAuthorizationStatus()).permissionIsGranted
  let messagesAreEnabled = canAccessMessagesDB()
  return notificationsAreEnabled && messagesAreEnabled
}
