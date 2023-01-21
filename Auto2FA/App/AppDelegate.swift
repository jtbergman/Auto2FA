//
//  AppDelegate.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/20/23.
//

import Foundation
import AppKit
import UserNotifications
import SQLite3
import RegexBuilder
import SwiftUI

var sent = Set<String>()

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    showOnboardingWindow()

    Task {
      let result = await askForLocalNotifications()
      print("Notificiations: \(result)")
    }

    Task {
      while true {
        let messages = observeMessagesDB().filter { !sent.contains($0.id) }
        let codes = extractSecurityCodes(messages)
        if let newestSecurityCode = codes.first {
          sent.insert(newestSecurityCode.id)
          copyToClipboard(newestSecurityCode.code)
          sendNotificationForOTP(newestSecurityCode.code)
        }
        try? await Task.sleep(nanoseconds: 5_000_000_000)
      }
    }
  }
}

struct Message {
  let id: String
  let text: String
}

struct SecurityCode {
  let id: String
  let code: String
}

extension AppDelegate {
  func showOnboardingWindow() {
    let window = OnboardingWindow()
    if let frame = window.screen?.visibleFrame {
      let offsetFromTop = window.frame.height + 25
      let offsetFromRight = window.frame.width + 25
      let initialPosition = CGPoint(
        x: frame.maxX - offsetFromRight,
        y: frame.maxY - offsetFromTop
      )
      window.setFrameOrigin(initialPosition)
      window.makeKeyAndOrderFront(nil)
    }
  }

  func extractSecurityCodes(_ messages: [Message]) -> [SecurityCode] {
    let regex = Regex {
      Capture {
        OneOrMore(.digit)
      }
    }
    var codes = [SecurityCode]()
    for message in messages {
      if let match = message.text.firstMatch(of: regex) {
        let code = String(match.output.0)
        codes.append(SecurityCode(id: message.id, code: code))
      }
    }
    print(codes)
    return codes
  }

  func askForLocalNotifications() async -> Bool {
    let notifications = UNUserNotificationCenter.current()
    let approved = try? await notifications.requestAuthorization(options: [.alert, .sound])
    return approved ?? false
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
}

extension AppDelegate {
  func canAccessMessagesDB() -> Bool {
    let home = FileManager.default.homeDirectoryForCurrentUser
    let messages = home.appending(path: "Library/Messages/chat.db")
    return FileManager.default.isReadableFile(atPath: messages.path())
  }
}

final class OnboardingWindow: NSWindow {
  override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
    super.init(
      contentRect: contentRect,
      styleMask: style,
      backing: backingStoreType,
      defer: flag
    )
    makeKeyAndOrderFront(nil)
    contentView = NSHostingView(rootView: OnboardingView())
  }
}
