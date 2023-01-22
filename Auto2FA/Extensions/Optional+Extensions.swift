//
//  Optional+Extensions.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation

infix operator ?>

extension Optional {
  /// Performs `perform` if and only if the optional is non-nil
  static func ?> (optional: Self, perform: (Wrapped) -> Void) {
    guard let wrapped = optional else {
      return
    }
    perform(wrapped)
  }
}
