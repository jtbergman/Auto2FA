//
//  MonitoringStatus.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation

enum MonitoringStatus {
  case active
  case needPermissions
  case paused

  func toggled() -> MonitoringStatus {
    if self == .needPermissions {
      return self
    }
    return self == .active ? .paused : .active
  }
}
