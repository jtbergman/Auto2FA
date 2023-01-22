//
//  UNAuthorizationStatus+Extensions.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation
import UserNotifications

extension UNAuthorizationStatus {
  var permissionIsGranted: Bool {
    return self == .authorized || self == .provisional
  }
}
