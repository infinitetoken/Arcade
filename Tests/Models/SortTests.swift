//
//  SortTests.swift
//  Arcade
//
//  Created by Aaron Wright on 2/5/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class SortTests: XCTestCase {
    
    func testSortDescriptors() {
        let sort1 = Sort(key: "test1", order: .ascending)
        let sort2 = Sort(key: "test2", order: .descending)
        
        let descriptor1 = sort1.sortDescriptor()
        let descriptor2 = sort2.sortDescriptor()
        
        XCTAssertEqual(descriptor1, NSSortDescriptor(key: "test1", ascending: true))
        XCTAssertEqual(descriptor2, NSSortDescriptor(key: "test2", ascending: false))
    }
    
}
