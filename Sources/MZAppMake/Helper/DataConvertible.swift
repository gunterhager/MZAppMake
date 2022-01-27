//
//  DataConvertible.swift
//  
//
//  Created by Gunter Hager on 04.12.17.
//  Copyright © 2017 Gunter Hager. All rights reserved.
//

import Foundation

enum DataConvertibleError: Error {
    case sizeMismatch(Int, Int)
    case wrongStringEncoding
}

protocol DataConvertible {
    init(data: Data) throws
    var data: Data { get }
}

extension DataConvertible {
    init(data: Data) throws {
        guard data.count == MemoryLayout<Self>.size else {
            throw DataConvertibleError.sizeMismatch(data.count, MemoryLayout<Self>.size)
        }
        // Copy data to make sure it is correctly align, otherwise loading from raw buffer pointer may crash
        let alignedData = Data(data)
        // Load self from raw buffer pointer
        self = alignedData.withUnsafeBytes { return $0.load(as: Self.self) }
    }
    
    var data: Data {
		return withUnsafePointer(to: self) { pointer in
			return Data(buffer: UnsafeBufferPointer(start: pointer, count: 1))
		}
    }
}

extension Bool: DataConvertible {}

extension UInt8: DataConvertible {}
extension UInt16: DataConvertible {}
extension UInt32: DataConvertible {}
extension UInt64: DataConvertible {}

extension Int8: DataConvertible {}
extension Int16: DataConvertible {}
extension Int32: DataConvertible {}
extension Int64: DataConvertible {}

extension Double: DataConvertible {}

extension String: DataConvertible {
    init(data: Data) throws {
        guard let raw = String(data: data, encoding: .ascii) else { throw DataConvertibleError.wrongStringEncoding }
        self = raw
    }
    
    var data: Data {
        return data(using: .ascii) ?? Data()
    }
}

extension Date: DataConvertible {
    init(data: Data) throws {
        let timestamp = try UInt32(data: data)
        self = Date(timeIntervalSince1970: Double(timestamp))
    }
    
    var data: Data {
        let timestamp = UInt32(timeIntervalSince1970)
        return timestamp.data
    }
}

extension Data: DataConvertible {
    init(data: Data) throws {
        self.init(data)
    }
    
    var data: Data {
        return self
    }
}
