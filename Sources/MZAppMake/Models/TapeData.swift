//
//  TapeData.swift
//  MZTapeRecorder
//
//  Created by Gunter Hager on 22.05.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation

struct TapeData {
    let bytes: [UInt8]
    let checkSum: UInt16

    init?(index: Int, length: UInt16, binary: [UInt8]) {
        var newIndex = index

//        print("Parsing tape data, starts at index: \(newIndex)")
        
        guard let bytes = Recording.readBytes(newIndex, length: Int(length), binary: binary) else { return nil }
        self.bytes = bytes.bytes
        newIndex = bytes.newIndex
        
        // Read checksum, for some reason it is big endian!
        guard let checkSum = Recording.readBytes(newIndex, length: 2, binary: binary) else { return nil }
        guard let checkSumValue = Recording.bigEndianUInt16(checkSum.bytes) else { return nil }
        
        guard checkSumValue == UInt16(bytes.checkSum) else {
            print("Tape data: check sum error")
            print("Expected: \(checkSumValue), calculated: \(bytes.checkSum)")
            return nil
        }
        self.checkSum = checkSumValue
        newIndex = checkSum.newIndex
        
//        print("Parsing tape data done, ends at index: \(newIndex)")
    }
    
    init?(bytes: [UInt8], length: UInt16) {
        guard bytes.count >= (Int(length) + Config.Counts.Header.count - 4) else { return nil }
        let startOfData = Config.Counts.Header.count
        let endOfData = startOfData + Int(length)
        self.bytes = [UInt8](bytes[startOfData ..< endOfData])
        self.checkSum = 0 // MZF files don't contain a check sum
    }
    
    /// Create tape data from data that represents the pure payload
    ///
    /// - Parameter data: payload data
    init(data: Data) {
        self.bytes = Array(data)
        self.checkSum = 0 // MZF files don't contain a check sum
    }

    var description: String {
        var result = "Tape data\n"
        result += "  Length: 0x\(String(format: "%04x", bytes.count)), \(bytes.count)\n"
        result += "  Check sum: 0x\(String(format: "%04x", checkSum))\n"
//        result += hexDumpStringForBytes(data)
        return result
    }

}

extension TapeData: Equatable {}

func ==(a: TapeData, b: TapeData) -> Bool {
    return a.bytes == b.bytes &&
        a.checkSum == b.checkSum
}
