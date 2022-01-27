//
//  WAVFile.swift
//  MZAppMake
//
//  Created by Gunter Hager on 15.06.18.
//

import Foundation

struct WAVHeader: DataConvertible {
    let fileDescription = "RIFF".data
    let fileSize: Data
    
    let waveDescription = "WAVE".data
    
    let formatDescription = "fmt ".data
    let formatHeaderBytes: [UInt8] = [
        0x10, 0x00, 0x00, 0x00, // Size of WAVE section chunck.
        0x01, 0x00,             // Wave type format.
        0x01, 0x00,             // Mono or stereo.
        0x44, 0xac, 0x00, 0x00, // Sample rate.
        0x44, 0xac, 0x00, 0x00, // Bytes per second.
        0x01, 0x00,             // Block alignment.
        0x08, 0x00,             // Bits per sample.
    ]
    
    let dataDescription = "data".data
    let dataSize: Data
    
    var bytes: [UInt8] {
        let part1 = Array(fileDescription
            + fileSize
            + waveDescription
            + formatDescription)
        let part2 = Array(dataDescription
            + dataSize)
        
        return part1
            + formatHeaderBytes
            + part2
    }
    
    init(dataSize: UInt32) {
        self.fileSize = (dataSize + 36).littleEndian.data
        self.dataSize = dataSize.littleEndian.data
    }
}

struct WAVFile {
    
    let header: WAVHeader
    let audioBytes: [UInt8]
    
    var bytes: [UInt8] {
        return header.bytes
            + audioBytes
    }
    
    init?(bytes: [UInt8]) {
        guard bytes.count <= UInt32.max else { return nil }
        self.header = WAVHeader(dataSize: UInt32(bytes.count))
        self.audioBytes = bytes
    }
    
}
