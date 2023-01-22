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
  private var db: OpaquePointer?
  private var preparedQuery: OpaquePointer?

  private lazy var messagesURL: URL = {
    let home = FileManager.default.homeDirectoryForCurrentUser
    let messages = home.appending(path: "Library/Messages/chat.db")
    return messages
  }()

  private var referenceDate: Int? {
    let referenceDate = Calendar.current.date(byAdding: .minute, value: minutesAgo, to: .now)
    return referenceDate ?> { Int($0.timeIntervalSinceReferenceDate) * 1_000_000_000 }
  }

  var lastShownCodeDate = UserDefaults.standard.integer(forKey: lastShownCodeDateKey) {
    didSet {
      UserDefaults.standard.set(lastShownCodeDate, forKey: lastShownCodeDateKey)
    }
  }

  init(applicationClient: ApplicationClient, notificationClient: NotificationClient) {
    self.application = applicationClient
    self.notifications = notificationClient
  }

  func close() {
    sqlite3_close(db)
    sqlite3_finalize(preparedQuery)
    (db, preparedQuery) = (nil, nil)
  }
  
  func canAccessMessagesDB() -> Bool {
    FileManager.default.isReadableFile(atPath: messagesURL.path())
  }

  func monitorForMessages() -> Task<Void, Never> {
    Task {
      while !Task.isCancelled {
        pollMessageDB()
          .extractSecurityCodes()
          .first ?> { mostRecentlyReceivedCode in
            Task {
              await MainActor.run {
                store.send(action: .showCode(mostRecentlyReceivedCode))
              }
            }
          }
        try? await Task.sleep(nanoseconds: securityCodePollFrequency)
      }
    }
  }

  /// Polls the database for new messages since a reference date
  ///
  /// Polling is used intentionally. It would be better to use `sqlite3_update_hook`, but our provided
  /// hook would replace the currently stored hook if one exists. This would risk breaking the iMessage
  /// implementation, so we have no choice but to using polling.
  private func pollMessageDB() -> [Message] {
    // Reuse the database connection or open a new one
    guard db != nil || sqlite3_open(messagesURL.path(), &db) == SQLITE_OK else {
      return []
    }

    // Create a reference date to fetch messages from
    guard let referenceDate = (referenceDate ?> { max($0, lastShownCodeDate) }) else {
      return []
    }

    // Create the raw SQL query statement using ? for our date parameter
    let query = """
      SELECT guid, text, is_from_me, date, service FROM message
        WHERE
          text IS NOT NULL
        AND
          is_from_me=false
        AND
          date > ?
        AND
          service="SMS"
        ORDER BY date DESC
      """

    // Create a reusable prepared statement, delete it if an error occurs
    guard preparedQuery != nil || sqlite3_prepare_v2(db, query, -1, &preparedQuery, nil) == SQLITE_OK else {
      sqlite3_finalize(preparedQuery)
      preparedQuery = nil
      return []
    }

    // Bind the reference date to the preparedQuery (nb: parameters are indexed from 1)
    guard sqlite3_bind_int64(preparedQuery, 1, sqlite3_int64(referenceDate)) == SQLITE_OK else {
      sqlite3_finalize(preparedQuery)
      preparedQuery = nil
      return []
    }

    // Get all rows associated with the query
    var rows = [Message]()
    while sqlite3_step(preparedQuery) == SQLITE_ROW {
      let guid = String(cString: sqlite3_column_text(preparedQuery, 0))
      let text = String(cString: sqlite3_column_text(preparedQuery, 1))
      let date = Int(sqlite3_column_int64(preparedQuery, 3))
      rows.append(Message(id: guid, text: text, date: date))
    }

    // Prepare the query to be reused and return results
    sqlite3_reset(preparedQuery)
    sqlite3_clear_bindings(preparedQuery)
    return rows
  }
}
