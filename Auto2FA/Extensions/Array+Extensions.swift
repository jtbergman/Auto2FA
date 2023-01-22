//
//  Array+Extensions.swift
//  Auto2FA
//
//  Created by JT Bergman on 1/22/23.
//

import Foundation
import RegexBuilder

extension Array where Element == Message {
  func extractSecurityCodes() -> [SecurityCode] {
    let securityCode = Reference(Substring.self)
    let regex = Regex {
      Capture(as: securityCode) {
        NegativeLookahead {
          One(.anyOf("-"))
        }
        Repeat(4...9) {
          One(.digit)
        }
      }
    }
    var codes = [SecurityCode]()
    for message in self {
      message.text.firstMatch(of: regex) ?> { match in
        let code = String(match[securityCode])
        codes.append(SecurityCode(id: message.id, code: code, date: message.date))
      }
    }
    return codes
  }
}
