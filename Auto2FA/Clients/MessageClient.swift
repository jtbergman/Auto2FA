//
//  MessageClient.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation
import SQLite3

final class MessageClient {
  private let application: ApplicationClient
  private let notifications: NotificationClient

  init(applicationClient: ApplicationClient, notificationClient: NotificationClient) {
    self.application = applicationClient
    self.notifications = notificationClient
  }
  
  func canAccessMessagesDB() -> Bool {
    let home = FileManager.default.homeDirectoryForCurrentUser
    let messages = home.appending(path: "Library/Messages/chat.db")
    return FileManager.default.isReadableFile(atPath: messages.path())
  }

  func monitorForMessages() -> Task<Void, Never> {
    Task {
      while !Task.isCancelled {
        let messages = observeMessagesDB().filter { !sent.contains($0.id) }
        extractSecurityCodes(messages).first ?> { code in
          sent.insert(code.id)
          application.copyToClipboard(code)
          notifications.sendNotification(for: code)
        }
        try? await Task.sleep(nanoseconds: 5_000_000_000)
      }
    }
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
