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
}
