//
//  TapeMark.swift
//  MZTapeRecorder
//
//  Created by Gunter Hager on 11.06.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation

struct TapeMarkCounts {
    let zeroCount: Int
    let markOneCount: Int
    let markZeroCount: Int
}

enum TapeMarkState {
    case start
    case countingZero
    case countingMarkOne
    case countingMarkZero
    case end
    case error
}

// State machine that allows to search for tape marks
class TapeMark {
    
    /// Configuration of counts
    let counts: TapeMarkCounts
    
    /// State of state machine
    var state = TapeMarkState.start
    
    /// Bit index
    var index = 0
    
    private var zeroCount = 0
    private var markOneCount = 0
    private var markZeroCount = 0
    
    init(counts: TapeMarkCounts) {
        self.counts = counts
    }
    
    /**
     Provides the next bit for the state machine.
     
     - parameter bit: Bit value of 0 or one, other values lead to Error state
     */
    func nextBit(_ bit: UInt8) -> TapeMarkState {
        guard bit <= 1 else {
            state = .error
            return state
        }
        
        // Transitions
        switch state {
            
        case .end, .error:
            // Don't increase index because state machine has halted
            return state
            
        case .start:
            if bit == 0 {
                zeroCount += 1
                state = .countingZero
                break
            }
            
            if bit == 1 {
                state = .error
                break
            }
            
        case .countingZero:
            if bit == 0 {
                zeroCount += 1
                break
            }
            
            if bit == 1 {
                if zeroCount >= counts.zeroCount {
                    markOneCount += 1
                    state = .countingMarkOne
                    break
                }
                else {
                    state = .error
                    break
                }
            }
            
        case .countingMarkOne:
            if bit == 0 {
                if markOneCount == counts.markOneCount {
                    markZeroCount += 1
                    state = .countingMarkZero
                    break
                }
                else {
                    state = .error
                    break
                }
            }
            
            if bit == 1 {
                markOneCount += 1
                break
            }
            
        case .countingMarkZero:
            if bit == 0 {
                markZeroCount += 1
                break
            }
            
            if bit == 1 {
                if markZeroCount == counts.markZeroCount {
                    state = .end
                    break
                }
                else {
                    state = .error
                    break
                }
            }
        }
        
        index += 1
        return state
    }
    
    func reset() {
        index = 0
        zeroCount = 0
        markOneCount = 0
        markZeroCount = 0
        state = .start
    }
}
