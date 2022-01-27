//
//  UInt16+Extension.swift
//  MZAppMake
//
//  Created by Gunter Hager on 16.06.18.
//

import Foundation

extension UInt16 {
    init?(hexString: String) {
        if hexString.hasPrefix("0x") {
            guard let number = UInt16(hexString.dropFirst(2), radix: 16) else { return nil }
            self = number
        } else {
            guard let number = UInt16(hexString) else { return nil }
            self = number
        }
    }
}
