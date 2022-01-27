//
//  HexDump.swift
//  MZTapeRecorder
//
//  Created by Gunter Hager on 22.05.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation

// hexdump.swift
//
// This file contains library functions for generating hex dumps.
//
// The functions intended for client use are
//
// - `printHexDumpForBytes(_:)`
// - `printHexDumpForStandardInput()`
// - `hexDumpStringForBytes(_:)`
// - `logHexDumpForBytes(_:)`
//
// The `forEachHexDumpLineForBytes(_:, processLine:)` function is available
// to implement hex dumps to other types of input sources and output
// destinations, and other lower-level functions are available to construct
// different formats of hex-dump output.



/// Split a sequence into equal-size chunks and process each chunk.
///
/// Each chunk will have the specified number of elements, except for the last chunk,
/// which will be as long as necessary for the remainder of the data.
///
/// - parameters:
///    - sequence: Sequence of data elements.
///    - perChunkCount: Number of elements in each chunk.
///    - processChunk: Function that takes an offset into the data and array of data elements.

public func forEachChunkOfSequence<S : Sequence>(
    _ sequence: S,
    perChunkCount: Int,
    processChunk: (Int, [S.Iterator.Element]) -> ())
{
    var offset = 0
    var chunk = Array<S.Iterator.Element>()
    for element in sequence {
        chunk.append(element)
        if chunk.count == perChunkCount {
            processChunk(offset, chunk)
            chunk.removeAll()
            offset += perChunkCount
        }
    }
    if chunk.count > 0 {
        processChunk(offset, chunk)
    }
}


/// Get hex representation of a byte.
///
/// - parameter byte: A `UInt8` value.
///
/// - returns: A two-character `String` of hex digits, with leading zero if necessary.

public func hexStringForByte(_ byte: UInt8) -> String {
    return String(format: "%02x", UInt(byte))
}


/// Get hex representation of an array of bytes.
///
/// - parameter bytes: A sequence of `UInt8` values.
///
/// - returns: A `String` of hex codes separated by spaces.

public func hexStringForBytes<S: Sequence>(_ bytes: S) -> String where S.Iterator.Element == UInt8
{
    return bytes.lazy.map(hexStringForByte).joined(separator: " ")
}


/// Get printable representation of character.
///
/// - parameter byte: A `UInt8` value.
///
/// - returns: A one-character `String` containing the printable representation, or "." if it is not printable.

public func printableCharacterForByte(_ byte: UInt8) -> String {
    return (isprint(Int32(byte)) != 0) ? String(UnicodeScalar(byte)) : "."
}


/// Get printable representation of an array of characters.
///
/// - parameter bytes: A sequence of `UInt8` values.
///
/// - returns: A `String` of characters containing the printable representations of the input bytes.

public func printableTextForBytes<S: Sequence>(_ bytes: S) -> String where S.Iterator.Element == UInt8
{
    return bytes.lazy.map(printableCharacterForByte).joined(separator: "")
}


/// Count of bytes printed per row in a hex dump.

public let HexBytesPerRow = 16


/// Generate hex-dump output line for a row of data.
///
/// Each line is a string consisting of an offset, hex representation
/// of the bytes, and printable ASCII representation.  There is no
/// end-of-line character included.
///
/// - parameters:
///    - offset: Numeric offset into the input data sequence.
///    - bytes: Sequence of `UInt8` values to be hex-dumped for this line.
///
/// - returns: A `String` with the format described above.

public func hexDumpLineForOffset<S: Sequence>(_ offset: Int, bytes: S) -> String where S.Iterator.Element == UInt8
{
    let hex = hexStringForBytes(bytes)
    let paddedHex = String(format: "%-47s", NSString(string: hex).utf8String!)
    let printable = printableTextForBytes(bytes)
    return String(format: "%08x  %@  %@", offset, paddedHex, printable)
}


/// Given a sequence of bytes, generate a series of hex-dump lines.
///
/// - parameters:
///    - bytes: Sequence of `UInt8` values to be hex-dumped.
///    - processLine: Function to be invoked for each generated line.

public func forEachHexDumpLineForBytes<S: Sequence>(_ bytes: S, processLine: (String) -> ()) where S.Iterator.Element == UInt8
{
    forEachChunkOfSequence(bytes, perChunkCount: HexBytesPerRow) { offset, chunk in
        let line = hexDumpLineForOffset(offset, bytes: chunk)
        processLine(line)
    }
}


/// Dump a sequence of bytes as hex to standard output.
///
/// - parameter bytes: Sequence of `UInt8` values to be hex-dumped.

public func printHexDumpForBytes<S: Sequence>(_ bytes: S) where S.Iterator.Element == UInt8
{
    forEachHexDumpLineForBytes(bytes) { print($0) }
}


/// Print hex dump for standard input to standard output.

public func printHexDumpForStandardInput() {
    let standardInputAsUInt8Sequence = AnyIterator { () -> UInt8? in
        let ch = getchar()
        return (ch == EOF) ? nil : UInt8(ch)
    }
    printHexDumpForBytes(standardInputAsUInt8Sequence)
}


/// Dump a sequence of bytes to a `String`.
///
/// - parameter bytes: Sequence of `UInt8` values to be hex-dumped.
///
/// - returns: A `String`, which may contain newlines.

public func hexDumpStringForBytes<S: Sequence>(_ bytes: S) -> String where S.Iterator.Element == UInt8
{
    var s = ""
    forEachHexDumpLineForBytes(bytes) { s += $0 + "\n" }
    return s
}


/// Dump a sequence of bytes to the log.
///
/// - parameter bytes: Sequence of `UInt8` values to be hex-dumped.

public func logHexDumpForBytes<S: Sequence>(_ bytes: S) where S.Iterator.Element == UInt8
{
    forEachHexDumpLineForBytes(bytes) { NSLog("%@", $0) }
}
