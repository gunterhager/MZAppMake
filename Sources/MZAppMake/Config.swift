//
//  Config.swift
//  MZTapeRecorder
//
//  Created by Gunter Hager on 13.05.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation

struct Config {
    
    struct Time {
        
        static let readTimeOut = TimeInterval(5.0)
        
    }
    
    struct Counts {
        static let tapeMark1 = TapeMarkCounts(zeroCount: 100, markOneCount: 40, markZeroCount: 40)
        static let tapeMark2 = TapeMarkCounts(zeroCount: 100, markOneCount: 20, markZeroCount: 20)

        struct TapeMark {
            struct Regular {
                struct First {
                    static let gap = 22000
                    static let one = 40
                    static let zero = 40
                }
                struct Second {
                    static let gap = 11000
                    static let one = 20
                    static let zero = 20
                }
            }
            struct Fast {
                struct First {
                    static let gap = 4000
                    static let one = 40
                    static let zero = 40
                }
                struct Second {
                    static let gap = 5000
                    static let one = 20
                    static let zero = 20
                }
            }
        }
        
        struct Header {
            static let count = 128
            static let bitCount = count + 2 + (count + 2) * 8
        }
        
        struct RepeatMark {
            static let zeroCount = 256
        }
    }
    
    struct Pulse {
        struct Bit {
            static let zero = UInt8(0x30)
            static let one = UInt8(0xd0)
        }
        struct Regular {
            struct Long {
                static let high = 21
                static let low = 21
            }
            struct Short {
                static let high = 11
                static let low = 11
            }
        }
        struct Fast {
            struct Long {
                static let high = 11
                static let low = 21
            }
            struct Short {
                static let high = 11
                static let low = 12
            }
        }
    }
    
}
