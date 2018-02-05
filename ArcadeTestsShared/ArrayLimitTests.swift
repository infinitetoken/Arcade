//
//  ArrayLimitTests.swift
//  Arcade
//
//  Created by Aaron Wright on 2/5/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class ArrayLimitTests: XCTestCase {
    
    func testLimit() {
        let array: [Int] = [1, 2, 3]
        
        let limit1 = array.limit(to: 0)
        
        XCTAssertEqual(limit1.count, 3)
        
        let limit2 = array.limit(to: 1)

        XCTAssertEqual(limit2.count, 1)
        
        let limit3 = array.limit(to: -1)
        
        XCTAssertEqual(limit3.count, 3)
    }
    
}
