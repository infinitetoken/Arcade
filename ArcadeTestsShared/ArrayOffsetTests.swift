//
//  ArrayOffsetTests.swift
//  Arcade
//
//  Created by Aaron Wright on 2/5/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class ArrayOffsetTests: XCTestCase {
    
    func testOffset() {
        let array: [Int] = [1, 2, 3]
        
        let offset1 = array.offset(by: 0)
        
        XCTAssertEqual(offset1.count, 3)
        
        let offset2 = array.offset(by: 5)
        
        XCTAssertEqual(offset2.count, 0)
        
        let offset3 = array.offset(by: 1)
        
        XCTAssertEqual(offset3.count, 2)
    }
    
}
