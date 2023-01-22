//
//  OnboardingWindow.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import AppKit
import Foundation
import SwiftUI

final class OnboardingWindow: NSWindow {
  override init(
    contentRect: NSRect,
    styleMask style: NSWindow.StyleMask,
    backing backingStoreType: NSWindow.BackingStoreType,
    defer flag: Bool
  ) {
    super.init(
      contentRect: contentRect,
      styleMask: style,
      backing: backingStoreType,
      defer: flag
    )
    makeKeyAndOrderFront(nil)
    isReleasedWhenClosed = false // fixes a double free crash
    contentView = NSHostingView(rootView: OnboardingView().environmentObject(store))
  }
}
