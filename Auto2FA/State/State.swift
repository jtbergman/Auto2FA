//
//  State.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import AppKit
import Foundation

struct State {
  /// The current status of the app to display to users
  var monitoringStatus: MonitoringStatus = .needPermissions

  /// A task that is either polling for permissions or 2FA codes
  var monitoringTask: Task<Void, Never>? {
    didSet {
      oldValue?.cancel()
    }
  }

  /// Holds a reference to the `OnboardingWindow` if it exists
  var onboardingWindow: NSWindow? {
    didSet {
      oldValue?.close()
    }
  }

  /// The deeplink URL for the full disk access permission in settings
  let fullDiskAccessSettingURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

  /// The URL for reporting issues with reading codes
  let reportIssueURL = "https://github.com/jtbergman/Auto2FA/issues/new?template=bug_report.md"
}
