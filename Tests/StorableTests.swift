//
//  StorableTests.swift
//  Arcade
//
//  Created by Aaron Wright on 2/5/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class StorableTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        Arcade.shared.addAdapter(InMemoryAdapter(), forKey: "Test")
    }
    
    override func tearDown() {
        super.tearDown()
        
        Arcade.shared.removeAdapter(forKey: "Test")
    }
    
}
