//
//  Recording.swift
//  MZTapeRecorder
//
//  Created by Gunter Hager on 13.05.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation
import AVFoundation

/**
 *  Represents a recording of a single file from the MZ-800
 */
struct Recording {

    let header: Header
    let tapeData: TapeData
    
    /**
     Creates a recording from a data buffer containing binary data (i.e. a stream of zeros and ones as read from the tape).
     
     - parameter binaryData: Buffer containing binary data.
     
     - returns: Returns a recording or nil if binary data is corrupt.
     */
    init?(binaryData: Data) {
        let binary = Recording.convertData(binaryData)
        var index = 0
        
        // Read header
        guard let header = Recording.readHeader(binary) else {
            MZError.log("Couldn't read header.")
            return nil
        }
        print("Loading \(header.header.name), \(header.header.attributeDescription)...")
        self.header = header.header
        index = header.newIndex

        // Read tape data
        guard let data = Recording.readTapeData(index, length: header.header.fileLength, binary: binary) else {
            MZError.log("Couldn't read tape data.")
            return nil
        }
        self.tapeData = data.data
    }
    
    /**
     Creates a recording from data in MZF file format.
     
     - parameter byteData: Data in MZF file format.
     
     - returns: Returns a recording or nil if data is corrupt.
     */
    init?(byteData: Data) {
        let bytes = Recording.convertData(byteData)
        
        guard let header = Header(bytes: bytes) else {
            MZError.log("Couldn't read header.")
            return nil
        }
        self.header = header
        guard let tapeData = TapeData(bytes: bytes, length: header.fileLength) else {
            MZError.log("Couldn't read tape data.")
            return nil
        }
        self.tapeData = tapeData
    }
    
    /// Create a recording from header and payload data.
    ///
    /// - Parameters:
    ///   - header: header
    ///   - data: payload data
    init(header: Header, data: Data) {
        self.header = header
        self.tapeData = TapeData(data: data)
    }
    
    /// Saves recording as MZF file.
    ///
    /// - Parameter url: URL to save the recording to.
    /// - Throws: throws when data can't be written.
    func save(_ url: URL) throws {
        let bytes = header.bytes + tapeData.bytes
		let data = Data(bytes)
		try data.write(to: url)
    }
    
    func saveAudio(_ url: URL, fast: Bool = false) throws {
//        print("saveAudio (\(header.bytes.count))\n\(hexDumpStringForBytes(header.bytes))")
        
        let audioBytes = AudioData(header: header, tapeData: tapeData).write(fast: fast)
        
        guard let wavFile = WAVFile(bytes: audioBytes) else {
            throw MZError(message: "Couldn't create WAV file bytes.")
        }
//        print("WAV: audio bytes: \(audioBytes.count)\n\(hexDumpStringForBytes(wavFile.header.bytes))")
        
        let data = Data(wavFile.bytes)
        try data.write(to: url)
    }
    
    // MARK: - Converting Data
    
    static func convertData(_ data: Data) -> [UInt8] {
        return Array(data)
    }
    
    
    // MARK: - High level read functions
    
    static func readHeader(_ binary: [UInt8]) -> (newIndex: Int, header: Header)? {
        var newIndex = 0
        
        print("Reading header, searching for tape mark 1")
        
        // Check for tape mark 1
        let tapeMark1 = TapeMark(counts: Config.Counts.tapeMark1)
        tapeMark1Loop: for bit in binary {
            let state = tapeMark1.nextBit(bit)
            switch state {
            case .end:
                print("Tape mark found, header starts at \(tapeMark1.index)")
                newIndex = tapeMark1.index
                break tapeMark1Loop
            case .error:
                print("Error while searching for tape mark at \(tapeMark1.index), retrying...")
                newIndex = tapeMark1.index
                tapeMark1.reset()
                tapeMark1.index = newIndex
            default:
                break
            }
        }
        
        guard newIndex < binary.count else {
            MZError.log("Couldn't read tape mark for header.", index: newIndex)
            return nil
        }
        print("Tape mark found, header starts at index: \(newIndex)")

        // Read header
        guard let header = Header(index: newIndex, binary: binary) else {
            MZError.log("Couldn't read header.", index: newIndex)
            return nil
        }
        newIndex += Config.Counts.Header.bitCount
        
        // Check for repeat mark
        guard let headerRepeatIndex = Recording.checkRepeatMark(newIndex, binary: binary) else {
            MZError.log("Couldn't read repeat mark for header.", index: newIndex)
            return nil
        }
        newIndex = headerRepeatIndex
        
        // Read duplicate header and compare
        guard let headerDuplicate = Header(index: newIndex, binary: binary) else {
            MZError.log("Couldn't read header duplicate.", index: newIndex)
            return nil
        }
        guard header == headerDuplicate else {
            MZError.log("Header and its duplicate differ.", index: newIndex)
            return nil
        }
        newIndex += Config.Counts.Header.bitCount
        
        return (newIndex: newIndex, header: header)
    }
    
    static func readTapeData(_ index: Int, length: UInt16, binary: [UInt8]) -> (newIndex: Int, data: TapeData)? {
        var newIndex = index
        
        // Check for tape mark 2
        let tapeMark2 = TapeMark(counts: Config.Counts.tapeMark2)
        tapeMark2Loop: for bit in binary {
            let state = tapeMark2.nextBit(bit)
            switch state {
            case .end:
                print("Tape mark found, data starts at \(tapeMark2.index)")
                newIndex = tapeMark2.index
                break tapeMark2Loop
            case .error:
                newIndex = tapeMark2.index
                tapeMark2.reset()
                tapeMark2.index = newIndex
            default:
                break
            }
        }

        guard newIndex < binary.count else {
            MZError.log("Couldn't read tape mark for data.", index: newIndex)
            return nil
        }
//        print("Tape mark 2 found, data starts at index: \(dataIndex)")

        // Read data
        print("Reading data...")
        if let data = TapeData(index: newIndex, length: length, binary: binary) {
            print("  done.")
            
            return (newIndex: newIndex, data: data)
        }
        else {
            print("Data corrupt, trying duplicate data")
            // Try to read duplicate data
            
            newIndex += Int(length) + 2 + (Int(length) + 2) * 8
            
            // Check for repeat mark
            guard let dataRepeatIndex = Recording.checkRepeatMark(newIndex, binary: binary) else {
                MZError.log("Couldn't read repeat mark for data.", index: newIndex)
                return nil
            }
            newIndex = dataRepeatIndex
            
            // Read data
            print("Reading duplicate data...")
            guard let dataDuplicate = TapeData(index: newIndex, length: length, binary: binary) else {
                MZError.log("Couldn't read duplicate data.", index: newIndex)
                return nil
            }
            print("  done.")
            
            newIndex += Int(length) + 2 + (Int(length) + 2) * 8
            
            return (newIndex: newIndex, data: dataDuplicate)
        }
    }
    
    
    // MARK: - Tape mark checks
    
    static func checkRepeatMark(_ index: Int, binary: [UInt8]) -> Int? {
        // Find index of tape mark by searching for > TapeMark.zeroCount zeros
        var newIndex = index

        // Mark starts with a single 1
        guard binary[newIndex] == 1 else { return nil }
        newIndex += 1
        
        // Check for zeros
        for zeroIndex in newIndex..<(newIndex + Config.Counts.RepeatMark.zeroCount) {
            guard binary[zeroIndex] == 0 else { return nil }
        }
        
        newIndex += Config.Counts.RepeatMark.zeroCount
        
        return newIndex
    }
    
    // MARK: - Conversion functions
    
    static func stringFromBytes(_ bytes: [UInt8]) -> String {
        return bytes.map { UnicodeScalar($0) }.reduce("") { $0 + String($1) }
    }
    
    static func littleEndianUInt16(_ bytes: [UInt8]) -> UInt16? {
        guard bytes.count == 2 else {
            MZError.log("Byte count not correct for little endian UInt16.")
            return nil
        }
        return UInt16(bytes[1]) << 8 + UInt16(bytes[0])
    }
    
    static func bigEndianUInt16(_ bytes: [UInt8]) -> UInt16? {
        guard bytes.count == 2 else {
            MZError.log("Byte count not correct for big endian UInt16.")
            return nil
        }
        return UInt16(bytes[0]) << 8 + UInt16(bytes[1])
    }
    
    
    // MARK: - Low level read functions
    
    /**
     Reads a byte starting at index given.
     
     - parameter index: Index to first bit of the byte in the binary. The first bit needs to be of value 1.
     - parameter binary: An array of bit values.
     
     - returns: Returns new index of and byte value or nil if byte couldn't be read.
     */
    static func readByte(_ index: Int, binary: [UInt8]) -> (newIndex: Int, byte: UInt8, checkSum: UInt16)? {
        // Check for start bit
        guard binary[index] == 1 else {
            MZError.log("Expected 1, got 0.", index: index)
            return nil
        }
        guard index + 8 < binary.count else {
            MZError.log("Binary too short to read byte.", index: index)
            return nil
        }
        
        var newIndex = index + 1
        var byte = UInt8(0)
        var checkSum = UInt16(0)
        
        for bit in binary[newIndex..<(newIndex + 8)] {
            byte = byte << 1 + UInt8(bit)
            checkSum += UInt16(bit)
        }
        
        newIndex += 8
        return (newIndex: newIndex, byte: byte, checkSum: checkSum)
    }
    
    // NOTE: This doesn't take into account the special MZ-800 characters
    
    /**
     Reads bytes of given length starting at index given.
     
     - parameter index:  Index to first bit of the first byte in the binary. The first bit needs to be of value 1.
     - parameter length: Length of the bytes to read. A byte here is made of 9 bits (1 start bit and 8 regular bits).
     - parameter binary: An array of bit values.
     
     - returns: Returns new index of and bytes array or nil if data couldn't be read.
     */
    static func readBytes(_ index: Int, length: Int, binary: [UInt8]) -> (newIndex: Int, bytes: [UInt8], checkSum: UInt16)? {
        var newBytes = [UInt8]()
        var newIndex = index
        var checkSum = 0
        
        // Check if enough bits are left in binary
//        guard (index + length * 9 - 1) < (binary.count - index) else {
//            MZError.log("Binary too short, expected to read \(length) bytes.", index: newIndex)
//            return nil
//        }
        
        for _ in 0..<length {
            guard let byte = Recording.readByte(newIndex, binary: binary) else {
                MZError.log("Couldn't read byte.", index: newIndex)
                return nil
            }
            newBytes.append(byte.byte)
            newIndex = byte.newIndex
            checkSum += Int(byte.checkSum)
        }
        // Handle check sum overflow: MZ check sum overflows silently and starts counting from zero.
        // So modulo 0x10000 (max. UInt16 + 1) will give the same result.
        let mzCheckSum = UInt16(checkSum % 0x10000)

        
        return (newIndex: newIndex, bytes: newBytes, checkSum: mzCheckSum)
    }
        
    // MARK: - Description
    
    var description: String {
        var result =  "Recording:\n"
        
        result += header.description
        result += tapeData.description
        
        return result
    }
}

