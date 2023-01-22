//
//  Actions.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation

enum Action {
  case cleanup
  case initialize
  case openFullDiskAccessSetting
  case pushNotificationsRequestAccess
  case reportIssue
  case showCode(SecurityCode)
  case selectMenuStatusItem
  case setMonitoringStatus(MonitoringStatus)
  case quit
}
