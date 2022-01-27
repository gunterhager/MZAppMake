//
//  AudioData.swift
//  MZAppMake
//
//  Created by Gunter Hager on 15.06.18.
//

import Foundation

struct AudioData {
    
    let header: Header
    let tapeData: TapeData
    
    init(header: Header, tapeData: TapeData) {
        self.header = header
        self.tapeData = tapeData
    }
    
    func write(fast: Bool = false) -> [UInt8] {
        if fast {
            return writeFast()
        } else {
            return writeRegular()
        }
    }
    
    private func writeFast() -> [UInt8] {
        let fast = true
        var bytes = [UInt8]()
        
        // Write tape mark 1
        bytes += writeTapeMark(
            gapLength: Config.Counts.TapeMark.Fast.First.gap,
            oneLength: Config.Counts.TapeMark.Fast.First.one,
            zeroLength: Config.Counts.TapeMark.Fast.First.zero,
            fast: fast)
        
        // Write header
        let (headerBytes, headerChecksum) = writeBytes(header.bytes, fast: fast)
        bytes += headerBytes
        bytes += writeChecksum(value: headerChecksum, fast: fast)
        
        // Write tape mark 2
        bytes += writeTapeMark(
            gapLength: Config.Counts.TapeMark.Fast.Second.gap,
            oneLength: Config.Counts.TapeMark.Fast.Second.one,
            zeroLength: Config.Counts.TapeMark.Fast.Second.zero,
            fast: fast)

        // Write tape data
        let (dataBytes, dataChecksum) = writeBytes(tapeData.bytes, fast: fast)
        bytes += dataBytes
        bytes += writeChecksum(value: dataChecksum, fast: fast)
        
        return bytes
    }
    
    private func writeRegular() -> [UInt8] {
        let fast = false
        var bytes = [UInt8]()
        
        // Write tape mark 1
        bytes += writeTapeMark(
            gapLength: Config.Counts.TapeMark.Regular.First.gap,
            oneLength: Config.Counts.TapeMark.Regular.First.one,
            zeroLength: Config.Counts.TapeMark.Regular.First.zero, fast: fast)
        
        // Write header
        let (headerBytes, headerChecksum) = writeBytes(header.bytes, fast: fast)
        bytes += headerBytes
        bytes += writeChecksum(value: headerChecksum, fast: fast)
        
        // Write gap
        bytes += writeGap(length: Config.Counts.RepeatMark.zeroCount, fast: fast)
        
        // Write header copy
        bytes += headerBytes
        bytes += writeChecksum(value: headerChecksum, fast: fast)
        
        // Write tape mark 2
        bytes += writeTapeMark(
            gapLength: Config.Counts.TapeMark.Regular.Second.gap,
            oneLength: Config.Counts.TapeMark.Regular.Second.one,
            zeroLength: Config.Counts.TapeMark.Regular.Second.zero,
            fast: fast)
        
        // Write tape data
        let (dataBytes, dataChecksum) = writeBytes(tapeData.bytes, fast: fast)
        bytes += dataBytes
        bytes += writeChecksum(value: dataChecksum, fast: fast)
        
        // Write gap
        bytes += writeGap(length: Config.Counts.RepeatMark.zeroCount, fast: fast)
        
        // Write tape data copy
        bytes += dataBytes
        bytes += writeChecksum(value: dataChecksum, fast: fast)
        
        return bytes
    }
    
    // MARK: - Parts
    
    private func writeGap(length: Int, fast: Bool) -> [UInt8] {
        return Array(repeating: shortPulse(fast: fast), count: length).flatMap { $0 }
    }
    
    private func writeTapeMark(gapLength: Int, oneLength: Int, zeroLength: Int, fast: Bool) -> [UInt8] {
        let result: [UInt8] = writeGap(length: gapLength, fast: fast)
            + Array(repeating: longPulse(fast: fast), count: oneLength).flatMap { $0 }
            + Array(repeating: shortPulse(fast: fast), count: zeroLength).flatMap { $0 }
        return result
            + longPulse(fast: fast)
            + longPulse(fast: fast)
    }
    
    private func writeByte(value: UInt8, fast: Bool) -> (bytes: [UInt8], checksum: UInt16) {
        var newChecksum = UInt16(0)
        var byte = value
        var bytes = [UInt8]()
        
        for _ in 0...7 {
            if (byte & UInt8(0x80)) == UInt8(0x80) {
                bytes += longPulse(fast: fast)
                newChecksum = newChecksum &+ 1
            } else {
                bytes += shortPulse(fast: fast)
            }
            byte <<= 1
        }
        bytes += longPulse(fast: fast)
        
        return (bytes: bytes, checksum: newChecksum)
    }
    
    private func writeBytes(_ bytes: [UInt8], fast: Bool) -> (bytes: [UInt8], checksum: UInt16) {
        return bytes.reduce(into: (bytes: [], checksum: 0)) { (result: inout (bytes: [UInt8], checksum: UInt16), byte) in
            let (bytes, checksum) = writeByte(value: byte, fast: fast)
            result.bytes += bytes
            result.checksum = result.checksum &+ checksum
        }
    }
    
    private func writeChecksum(value: UInt16, fast: Bool) -> [UInt8] {
        // Checksums are written as big endian
        let data = value.bigEndian.data
        let result = data.reduce(into: []) { (result: inout [UInt8], byte) in
            let (bytes, _) = writeByte(value: byte, fast: fast)
            result += bytes
        }
        return result + longPulse(fast: fast)
    }
    
    // MARK: - Pulses
    
    private func longPulse(fast: Bool) -> [UInt8] {
        if fast {
            return Array(repeating: Config.Pulse.Bit.zero, count: Config.Pulse.Fast.Long.high)
                + Array(repeating: Config.Pulse.Bit.one, count: Config.Pulse.Fast.Long.low)
        } else {
            return Array(repeating: Config.Pulse.Bit.zero, count: Config.Pulse.Regular.Long.high)
                + Array(repeating: Config.Pulse.Bit.one, count: Config.Pulse.Regular.Long.low)
        }
    }
    
    private func shortPulse(fast: Bool) -> [UInt8] {
        if fast {
            return Array(repeating: Config.Pulse.Bit.zero, count: Config.Pulse.Fast.Short.high)
                + Array(repeating: Config.Pulse.Bit.one, count: Config.Pulse.Fast.Short.low)
        } else {
            return Array(repeating: Config.Pulse.Bit.zero, count: Config.Pulse.Regular.Short.high)
                + Array(repeating: Config.Pulse.Bit.one, count: Config.Pulse.Regular.Short.low)
        }
    }
    
}
