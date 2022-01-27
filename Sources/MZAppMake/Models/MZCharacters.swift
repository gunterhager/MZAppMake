//
//  MZCharacters.swift
//  MZTapeRecorder
//
//  Created by Gunter Hager on 12.06.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation

struct MZCharacters {
    
    // MARK: - From MZ-ASCII to UTF-8 strings
    
    /// Translate a string in MZ-ASCII to UTF-8 string.
    /// - Note: This translation is lossy since certain characters can't be mapped.
    ///
    /// - Parameter mzString: String in MZ-ASCII
    /// - Returns: String in UTF-8
    static func translate(mzString: String) -> String {
        return mzString.unicodeScalars.reduce("") { $0 + String(MZCharacters.translate(mzCharacter: $1)) }
    }
    
    /// Translate a character in MZ-ASCII to UTF-8 scalar.
    /// - Note: This translation is lossy since certain characters can't be mapped.
    ///
    /// - Parameter mzCharacter: Character in MZ-ASCII
    /// - Returns: The mapped character as UTF-8 scalar
    static func translate(mzCharacter: UnicodeScalar) -> UnicodeScalar {
        switch mzCharacter.value {
            
        // CR
        case 0x0D:
            return mzCharacter
            
        // Standard ASCII
        case 0x20...0x5D:
            return mzCharacter
            
        // SHARP characters
        case 0x5E...0xFF:
            if let result = MZASCII[mzCharacter.value] {
                return result
            }
            else {
                return "."
            }
            
        // Character not printable or not existant in UNICODE
        default:
            return "."
        }
    }
    
    // MARK: - From MZ-ASCII strings to UTF-8
    
    /// Translate a string in MZ-ASCII to UTF-8 string.
    /// - Note: This translation is lossy since certain characters can't be mapped.
    ///
    /// - Parameter string: String in UTF-8
    /// - Returns: String in MZ-ASCII
    static func translate(string: String) -> String {
        return string.unicodeScalars.reduce("") { $0 + String(MZCharacters.translate(character: $1)) }
    }
    
    /// Translate a character in UTF-8 scalar to MZ-ASCII.
    /// - Note: This translation is lossy since certain characters can't be mapped.
    ///
    /// - Parameter character: Character in UTF-8
    /// - Returns: The mapped character as MZ-ASCII scalar
    static func translate(character: UnicodeScalar) -> UnicodeScalar {
        switch character.value {
            
        // CR
        case 0x0D:
            return character
            
        // Standard ASCII
        case 0x20...0x5D:
            return character
            
        // SHARP characters
        case 0x5E...0xFF:
            if let result = inverseMZASCII[character.value] {
                return result
            }
            else {
                return "."
            }
            
        // Character not printable or not existant in UNICODE
        default:
            return "."
        }
    }
    
    /// SHARP MZ-800 ASCII Table (SHARP uses a non-standard variant of ASCII)
    static let MZASCII: [UInt32: UnicodeScalar] = [
        
        // Standard ASCII ' ' - ']' (0x20 - 0x5D)
        //    0x21: "!",
        //    0x22: "\"",
        //    0x23: "#",
        //    0x24: "$",
        //    0x25: "%",
        //
        //    0x26: "&",
        //    0x27: "'",
        //    0x28: "(",
        //    0x29: ")",
        //    0x2A: "*",
        //
        //    0x2B: "+",
        //    0x2C: ",",
        //    0x2D: "-",
        //    0x2E: ".",
        //    0x2F: "/",
        
        // SHARP ASCII
        0x7B: "°",
        
        0x80: "}",
        
        0x8B: "^",
        
        0x90: "_",
        0x92: "e",
        0x93: "`",
        0x94: "~",
        
        0x96: "t",
        0x97: "g",
        0x98: "h",
        0x9A: "b",
        
        0x9B: "x",
        0x9C: "d",
        0x9D: "r",
        0x9E: "p",
        0x9F: "c",
        
        0xA0: "q",
        0xA1: "a",
        0xA2: "z",
        0xA3: "w",
        0xA4: "s",
        0xA5: "u",
        
        0xA6: "i",
        0xA8: "Ö",
        0xA9: "k",
        0xAA: "f",
        
        0xAB: "v",
        0xAD: "ü",
        0xAE: "ß",
        0xAF: "j",
        
        0xB0: "n",
        0xB2: "Ü",
        0xB3: "m",
        
        0xB7: "o",
        0xB8: "l",
        0xB9: "Ä",
        0xBA: "ö",
        
        0xBB: "ä",
        0xBD: "y",
        0xBE: "{",
        
        0xFF: "π"
    ]
    
    static var inverseMZASCII: [UInt32: UnicodeScalar] = {
        let inverse = MZASCII.reduce(into: [:]) { (result: inout [UInt32: UnicodeScalar], pair) in
            let (mzCharacter, character) = pair
            if let mzScalar = UnicodeScalar(mzCharacter) {
                result[character.value] = mzScalar
            }
        }
        return inverse
    }()
    
}
