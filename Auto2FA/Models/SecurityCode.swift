//
//  SecurityCode.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/21/23.
//

import Foundation

struct SecurityCode: CustomStringConvertible {
  let id: String
  let code: String
  let date: Int

  /// Ensure the code is not logged when debugging
  var description: String {
    "\(id) Code: \(String(repeating: "#", count: code.count))"
  }
}
