//
//  Reducer.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import AppKit
import Foundation
import RegexBuilder

typealias Reducer = (State, Action, Environment) -> State

func reducer(state: State, action: Action, environment: Environment) -> State {
  switch action {
  case .cleanup:
    environment.notifications.removeAllDeliveredNotifications()
    return state

  case .initialize:
    environment.notifications.removeAllDeliveredNotifications()
    var state = state
    state.monitoringTask = environment.permissions.monitorForPermissions()
    return state

  case .openFullDiskAccessSetting:
    environment.application.open(URL(string: state.fullDiskAccessSettingURL))
    return state

  case .pushNotificationsRequestAccess:
    environment.notifications.requestAuthorization()
    return state

  case .reportIssue:
    environment.application.open(URL(string: state.reportIssueURL))
    return state

  case .selectMenuStatusItem:
    return reducer(
      state: state,
      action: .setMonitoringStatus(state.monitoringStatus.toggle()),
      environment: environment
    )

  case .setMonitoringStatus(let status):
    var state = state
    switch status {
    case .active:
      state.onboardingWindow = nil
      state.monitoringTask = environment.messages.monitorForMessages()
    case .needPermissions:
      state.onboardingWindow = environment.application.showOnboardingWindow()
      state.monitoringTask = environment.permissions.monitorForPermissions()
    case .paused:
      state.onboardingWindow = nil
      state.monitoringTask = nil
    }
    state.monitoringStatus = status
    return state

  case .quit:
    environment.application.terminate()
    return state
  }
}


// MARK: Helpers

func extractSecurityCodes(_ messages: [Message]) -> [SecurityCode] {
  let regex = Regex {
    Capture {
      OneOrMore(.digit)
    }
  }
  var codes = [SecurityCode]()
  for message in messages {
    message.text.firstMatch(of: regex) ?> { match in
      let code = String(match.output.0)
      codes.append(SecurityCode(id: message.id, code: code))
    }
  }
  print(codes)
  return codes
}
