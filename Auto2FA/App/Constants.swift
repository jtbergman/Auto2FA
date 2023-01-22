//
//  Constants.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation

/// How many minutes ago should messages be observed from
let minutesAgo = -3

/// How frequently should the app poll for new security codes (in nanoseconds)
let securityCodePollFrequency: UInt64 = 3_000_000_000

/// How frequently should the app poll permissions while waiting for access (in nanoseconds)
let permissionsGrantedPollFrequency: UInt64 = 3_000_000_000

/// How long should a "Copied to Clipboard" notification show before automatic dismissal (in nanoseconds)
let localNotificationShowDuration: UInt64 = 5_000_000_000

/// The `UserDefault` associated with the last shown 2FA code. Used to prevent sending multiple notifications.
let lastShownCodeDateKey = "com.Auto2FA.lastShownCodeDate"

/// The deeplink URL for the full disk access permission in settings
let fullDiskAccessSettingURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

/// The URL for reporting issues with reading codes
let reportIssueURL = "https://github.com/jtbergman/Auto2FA/issues/new?template=bug_report.md"
