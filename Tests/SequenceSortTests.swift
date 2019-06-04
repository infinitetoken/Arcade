//
//  SequenceSortTests.swift
//  Arcade
//
//  Created by Aaron Wright on 2/5/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class SequenceSortTests: XCTestCase {
    
    func testSorting() {
        let sequence: [Int] = [3, 1, 2]
        let sortDescriptor = NSSortDescriptor(key: "self", ascending: true)
        
        XCTAssertEqual(sequence, [3, 1, 2])
        
        let sorted = sequence.sorted(with: [sortDescriptor])
        
        XCTAssertEqual(sorted, [1, 2, 3])
    }
    
}
