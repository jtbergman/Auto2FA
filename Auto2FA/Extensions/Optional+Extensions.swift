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
  ///
  /// For example, to open a URL if it is not nil use the following
  /// ```
  /// URL(string: "https://example.com") ?> { NSWorkspace.shared.open($0) }
  /// ```
  ///
  /// Another example returns the time elapsed since the reference date
  /// ```
  /// let referenceDate = Calendar.current.date(byAdding: .minute, value: -5, to: .now)
  /// return referenceDate ?> { Int($0.timeIntervalSinceReferenceDate }
  /// ```
  @discardableResult static func ?> <T>(optional: Self, perform: (Wrapped) -> T) -> T? {
    guard let wrapped = optional else {
      return nil
    }
    return perform(wrapped)
  }
}
