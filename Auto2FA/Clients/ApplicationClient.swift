//
//  ApplicationClient.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import AppKit
import Foundation

final class ApplicationClient {
  func copyToClipboard(_ code: SecurityCode) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(code.code, forType: .string)
  }

  func open(_ url: URL?) {
    url ?> { NSWorkspace.shared.open($0) }
  }

  func terminate() {
    NSApplication.shared.terminate(nil)
  }

  func showOnboardingWindow() -> NSWindow {
    let window = OnboardingWindow()
    window.screen?.visibleFrame ?> { frame in
      let offsetX = window.frame.width / 2
      let offsetY = window.frame.height / 2
      let initialPosition = CGPoint(
        x: frame.midX - offsetX,
        y: frame.midY - offsetY
      )
      window.setFrameOrigin(initialPosition)
    }
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    return window
  }
}
