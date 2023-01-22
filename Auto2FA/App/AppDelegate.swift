//
//  AppDelegate.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/20/23.
//

import Foundation
import AppKit
import UserNotifications
import SQLite3
import RegexBuilder
import SwiftUI

var sent = Set<String>()

let store = Store(state: State())

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    store.send(action: .initialize)
  }
}
