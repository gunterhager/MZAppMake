//
//  Header.swift
//  MZTapeRecorder
//
//  Created by Gunter Hager on 15.05.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation

struct Header {

    static let attributes = [
        0x01: "OBJ (Machine Program)",
        0x05: "BTX (BASIC Program)",
        0x94: "TXT (Text File)",
        ]
    
    let attribute: UInt8
    let nameBytes: [UInt8]
    let mzName: String
    let name: String
    let fileLength: UInt16
    let loadingAddress: UInt16
    let startAddress: UInt16
    let commentBytes: [UInt8]
    let checkSum: UInt16
    
    /// Byte data of the header. This doesn't contain the checksum.
    let bytes: [UInt8]

    var attributeDescription: String {
        let attributeLookup = Header.attributes[Int(self.attribute)] ?? ""
        return "0x\(String(format: "%02x", self.attribute)) " + attributeLookup
    }

    /// Create header for an OBJ file (machine program).
    ///
    /// - Parameters:
    ///   - name: name of the program (will be converted to MZ-ASCII)
    ///   - fileLength: length of the file in bytes
    ///   - loadingAddress: address where the file will be loaded to
    ///   - startAddress: address where the program will be started, i.e. the monitor will jump there
    init?(name: String, fileLength: UInt16, loadingAddress: UInt16, startAddress: UInt16) {
        guard name.count < 17 else { return nil }
        self.name = name
        self.mzName = MZCharacters.translate(string: name)
        
        // Create name bytes and pad with zeros if needed
        let nameBytes = (self.mzName + "\r")
            .unicodeScalars
            .map { UInt8($0.value) }
        self.nameBytes = nameBytes + Array(repeating: 0, count: 17 - nameBytes.count)
        
        // Set attribute to OBJ
        self.attribute = 0x01
        
        self.fileLength = fileLength
        self.loadingAddress = loadingAddress
        self.startAddress = startAddress
        self.commentBytes = Array(repeating: 0, count: 104)
        self.checkSum = 0
        
        self.bytes = self.attribute.data
            + self.nameBytes
            + self.fileLength.littleEndian.data
            + self.loadingAddress.littleEndian.data
            + self.startAddress.littleEndian.data
            + self.commentBytes
    }
    
    /// Create header from binary data read directly from tape
    ///
    /// - Parameters:
    ///   - index: start index in the binary data
    ///   - binary: binary data
    init?(index: Int, binary: [UInt8]) {
        var newIndex = index
        var readCheckSum = UInt16(0)
        var newBytes = [UInt8]()
        
//        print("Parsing header, starts at index: \(newIndex)")
        
        // Get attribute byte
        guard let attribute = Recording.readByte(newIndex, binary: binary) else { return nil }
        newBytes.append(attribute.byte)
        self.attribute = attribute.byte
        newIndex = attribute.newIndex
        readCheckSum += attribute.checkSum
        
        // Get name (17 characters, name is terminated by CR, 0x0D)
        // NOTE: This doesn't take into account the special MZ-800 characters
        guard let nameBytes = Recording.readBytes(newIndex, length: 17, binary: binary) else { return nil }
        newBytes += nameBytes.bytes
        self.nameBytes = nameBytes.bytes
        let rawName = Recording.stringFromBytes(nameBytes.bytes)
        guard let processedName = rawName.components(separatedBy: "\r").first else { return nil }
        self.mzName = processedName
        
        // Translated name, MZ-800 characters to UNICODE
        self.name = MZCharacters.translate(mzString: self.mzName)

        newIndex = nameBytes.newIndex
        readCheckSum += nameBytes.checkSum
        
        // Get file length
        guard let fileLength = Recording.readBytes(newIndex, length: 2, binary: binary) else { return nil }
        newBytes += fileLength.bytes
        guard let fileLengthValue = Recording.littleEndianUInt16(fileLength.bytes) else { return nil }
        self.fileLength = fileLengthValue
        newIndex = fileLength.newIndex
        readCheckSum += fileLength.checkSum

        // Get loading address
        guard let loadingAddress = Recording.readBytes(newIndex, length: 2, binary: binary) else { return nil }
        newBytes += loadingAddress.bytes
        guard let loadingAddressValue = Recording.littleEndianUInt16(loadingAddress.bytes) else { return nil }
        self.loadingAddress = loadingAddressValue
        newIndex = loadingAddress.newIndex
        readCheckSum += loadingAddress.checkSum

        // Get start address
        guard let startAddress = Recording.readBytes(newIndex, length: 2, binary: binary) else { return nil }
        newBytes += startAddress.bytes
        guard let startAddressValue = Recording.littleEndianUInt16(startAddress.bytes) else { return nil }
        self.startAddress = startAddressValue
        newIndex = startAddress.newIndex
        readCheckSum += startAddress.checkSum

        // Skip comment (104 bytes), unused
        guard let commentBytes = Recording.readBytes(newIndex, length: 104, binary: binary) else { return nil }
        newBytes += commentBytes.bytes
        self.commentBytes = commentBytes.bytes
        newIndex = commentBytes.newIndex
        readCheckSum += commentBytes.checkSum

        // Read checksum, for some reason it is big endian!
        guard let checkSum = Recording.readBytes(newIndex, length: 2, binary: binary) else { return nil }
        guard let checkSumValue = Recording.bigEndianUInt16(checkSum.bytes) else { return nil }
        guard checkSumValue == readCheckSum else {
            print("Header: check sum error")
            
            var result = "Header\n"
            result += "  Attribute: 0x\(String(format: "%02x", self.attribute))\n"
            result += "  Name: \(mzName)\n"
            result += "  File length: 0x\(String(format: "%04x", self.fileLength)), \(self.fileLength)\n"
            result += "  Loading address: 0x\(String(format: "%04x", self.loadingAddress))\n"
            result += "  Start address: 0x\(String(format: "%04x", self.startAddress))\n"
            result += "  Comment:\n"
            result += hexDumpStringForBytes(self.commentBytes)
            result += "  Check sum: 0x\(String(format: "%04x", checkSumValue))\n"
            print(result)
            
            print("Expected: \(checkSumValue), calculated: \(readCheckSum)")
            return nil
        }
        self.checkSum = checkSumValue
        newIndex = checkSum.newIndex
        
        self.bytes = newBytes
        
//        print("Parsing header done, ends at index: \(newIndex)")
    }
    
    /// Create header from MZF tape file
    ///
    /// - Parameter bytes: data from tape file
    init?(bytes: [UInt8]) {
        guard bytes.count >= Config.Counts.Header.count - 2 else { return nil }
        self.attribute = bytes[0]
        self.nameBytes = [UInt8](bytes[1...17])
        let rawName = Recording.stringFromBytes(self.nameBytes)
        guard let processedName = rawName.components(separatedBy: "\r").first else { return nil }
        self.mzName = processedName
        self.name = MZCharacters.translate(mzString: self.mzName)
        self.fileLength = Recording.littleEndianUInt16([UInt8](bytes[18...19]))!
        self.loadingAddress = Recording.littleEndianUInt16([UInt8](bytes[20...21]))!
        self.startAddress = Recording.littleEndianUInt16([UInt8](bytes[22...23]))!
        self.commentBytes = [UInt8](bytes[24...127])
        self.checkSum = 0 // MZF files don't contain a checksum
        self.bytes = Array(bytes[0..<(Config.Counts.Header.count)])
    }
    
    var description: String {
        var result = "Header\n"
        result += "  Attribute: \(attributeDescription)\n"
        result += "  Name: \(name)\n"
        result += "  File length: 0x\(String(format: "%04x", fileLength)), \(fileLength)\n"
        result += "  Loading address: 0x\(String(format: "%04x", loadingAddress))\n"
        result += "  Start address: 0x\(String(format: "%04x", startAddress))\n"
        result += "  Comment:\n"
        result += hexDumpStringForBytes(commentBytes)
        result += "  Check sum: 0x\(String(format: "%04x", checkSum))\n"
        return result
    }
    
}

extension Header: Equatable {}

func ==(a: Header, b: Header) -> Bool {
    return a.attribute == b.attribute &&
        a.nameBytes == b.nameBytes &&
        a.fileLength == b.fileLength &&
        a.loadingAddress == b.loadingAddress &&
        a.startAddress == b.startAddress &&
        a.commentBytes == b.commentBytes &&
        a.checkSum == b.checkSum
}

