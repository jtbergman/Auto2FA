//
//  ApplicationClient.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import AppKit
import Foundation

final class ApplicationClient {
  func open(_ url: URL?) {
    url ?> { NSWorkspace.shared.open($0) }
  }

  func terminate() {
    NSApplication.shared.terminate(nil)
  }
}
