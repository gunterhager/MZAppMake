//
//  MZError.swift
//  MZTapeRecorder
//
//  Created by Gunter Hager on 01.06.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation

struct MZError: Error, CustomStringConvertible {
	var description: String {
		if let index = index {
			return "at index \(index): \(message)"
		}
		else {
			return message
		}
	}
    
    let message: String
    let index: Int?
    
    init(message: String, index: Int? = nil) {
        self.message = message
        self.index = index
    }
    
    func log() {
        if let index = index {
            MZError.log(message, index: index)
        }
        else {
            MZError.log(message)
        }
    }
    
    static func log(_ text: String) {
        print("Error: \(text)")
    }

    static func log(_ text: String, index: Int) {
        print("Error at index \(index): \(text)")
    }

}
