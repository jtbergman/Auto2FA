# 👨🏼‍💻 Auto2FA

This document includes technical details for anyone looking to recreate or understand the functionality of Auto2FA.

## Accessing the iMessage DB

Accessing the iMessage DB requires the following changes in code:

- The app cannot be sandboxed (delete the capability from Target > Signing & Capabilities)
- The user must grant full disk access

To reduce friction, deeplink to the “full disk access” setting using:

```swift
guard let fullDiskAccessURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
  return
}
NSWorkspace.shared.open(fullDiskAccessURL)
```

The following code checks if the app has read access to the DB without loading it into memory:

```swift
func canAccessMessagesDB() -> Bool {
  let home = FileManager.default.homeDirectoryForCurrentUser
  let messages = home.appending(path: "Library/Messages/chat.db")
  return FileManager.default.isReadableFile(atPath: messages.path())
}
```

## Reading the iMessage DB

The relevant content is stored in the `message` table of the database

- Use the `guid` to only send a notification once
- Use the `text` column to get the message content
- Use the `date` column to only fetch recent messages
- Use the `is_from_me` column to filter outgoing messages
- Use the `service` column to filter out iMessages (note: I’m unsure if 2FA can use iMessage)

The following SQL statement will fetch all SMS messages since the reference date

```sql
SELECT guid, text, is_from_me, date, service FROM message
  WHERE
    text IS NOT NULL
  AND
    is_from_me=false
  AND
    date >= datetime(referenceDate)
  AND
    service="SMS"
  ORDER BY date DESC;
```

To create and execute this SQL statement in Swift

```swift
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
        date >= ?
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
    rows.append(Message(id: guid, text: text))
  }

  // Prepare the query to be reused and return results
  sqlite3_reset(preparedQuery)
  sqlite3_clear_bindings(preparedQuery)
  return rows
}
```

The `referenceDate` used above has the following format to match the one used by Apple. We use either this date or the date associated with the most recently shown code. This ensures that we don’t show an older code after showing a newer code (or send multiple notifications for the same code).

```swift
private var referenceDate: Int? {
  guard let referenceDate = Calendar.current.date(byAdding: .minute, value: minutesAgo, to: .now) else {
    return nil
  }
  return Int(referenceDate.timeIntervalSinceReferenceDate) * 1_000_000_000
}
```

The `SQLite3` module is used directly without a third-party library. There are a few reasons for using the built-in module: it reduces the app binary size, it prevents third-party code from possibly accessing the user’s iMessage DB, and it makes it clear exactly what code is running so we don’t risk breaking the database. For example, if third-party code used `sqlite3_update_hook` it would cause the issue mentioned in the docstring above.

## Polling for Security Codes

Finally, the code should poll for messages on some fixed interval. This code uses five seconds:

```swift
func monitorForMessages() -> Task<Void, Never> {
  Task {
    while !Task.isCancelled {
      pollMessageDB()
        .extractSecurityCodes(messages)
        .first ?> { mostRecentlyReceivedCode in
          Task {
            await MainActor.run {
              store.send(action: .showCode(mostRecentlyReceivedCode))
            }
          }
        }

      // Task.sleep does not block a thread so is safe to use (unlike Thread.sleep)
      try? await Task.sleep(nanoseconds: 5_000_000_000)
    }
  }
}
```

Once we receive a message, the security code can be extracted with a simple regex

```swift
extension Array where Element == Message {
  func extractSecurityCodes() -> [SecurityCode] {
    // Type-safe reference to a match
    let securityCode = Reference(Substring.self)

    // Matches 4 to 9 digits.
    // Excludes matches preceded by "-" to avoid the last 4 digits of phone numbers.
    let regex = Regex {
      Capture(as: securityCode) {
        NegativeLookahead {
          One(.anyOf("-"))
        }
        Repeat(4...9) {
          One(.digit)
        }
      }
    }

    // Check all messages for a match
    var codes = [SecurityCode]()
    for message in self {
      message.text.firstMatch(of: regex) ?> { match in
        let code = String(match[securityCode])
        codes.append(SecurityCode(id: message.id, code: code, date: message.date))
      }
    }
    return codes
  }
}
```

The most recent code is sent to the store which triggers the following updates

```swift
messages.lastShownCodeDate = mostRecentlyReceivedCode.date
application.copyToClipboard(mostRecentlyReceivedCode)
notifications.sendNotification(for: mostRecentlyReceivedCode)
```

## Resources

The following blogs were helpful for completing this project

- [Getting a Redux Vibe Into SwiftUI](https://www.kodeco.com/22096649-getting-a-redux-vibe-into-swiftui#toc-anchor-017)
- [Building a lightweight SQLite wrapper in Swift](https://shareup.app/blog/building-a-lightweight-sqlite-wrapper-in-swift/)
- [Beyond the Sanbox: Singing and distributing macOS apps outside the App Store](https://www.appcoda.com/distribute-macos-apps/)

The following projects are similar to this project

- [SoFriengly/2FHey](https://github.com/SoFriendly/2fhey)
- [Using SQL to Look Through All of Your iMessage Text Messages](https://spin.atomicobject.com/2020/05/22/search-imessage-sql/)
