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
  var monitoringStatus: MonitoringStatus = .needPermissions(messages: false, notifications: false)

  /// A task that polls for 2FA codes
  var messageMonitoringTask: Task<Void, Never>? {
    didSet {
      oldValue?.cancel()
    }
  }

  /// A task the polls for permissions
  var permissionsMonitoringTask: Task<Void, Never>? {
    didSet {
      oldValue?.cancel()
    }
  }

  /// Holds a reference to the `OnboardingWindow` if it exists
  var onboardingWindow: NSWindow? {
    willSet {
      onboardingWindow?.close()
    }
  }
}
