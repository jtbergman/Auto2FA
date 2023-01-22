//
//  MonitoringStatus.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation

enum MonitoringStatus {
  case active
  case paused
  case needPermissions(messages: Bool, notifications: Bool)

  func toggle() -> MonitoringStatus {
    switch self {
    case .active:
      return .paused
    case .paused:
      return .active
    case .needPermissions:
      return self
    }
  }
}
