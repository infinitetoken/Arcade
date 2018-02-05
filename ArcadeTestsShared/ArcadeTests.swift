//
//  ArcadeTests.swift
//  ArcadeTests
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class ArcadeTests: XCTestCase {
    
    var arcade: Arcade? = Arcade()
    
    override func setUp() {
        super.setUp()
        
        self.arcade = Arcade()
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.arcade = nil
    }
    
    func testCanInitialize() {
        XCTAssertNotNil(self.arcade)
    }
    
    func testCanAddAdapter() {
        let adapter = InMemoryAdapter()
        self.arcade?.addAdapter(adapter, forKey: "Test")
        XCTAssertNotNil(self.arcade?.adapter(forKey: "Test"))
    }
    
    func testCanRemoveAdapter() {
        let adapter = InMemoryAdapter()
        self.arcade?.addAdapter(adapter, forKey: "Test")
        XCTAssertNotNil(self.arcade?.adapter(forKey: "Test"))
        self.arcade?.removeAdapter(forKey: "Test")
        XCTAssertNil(self.arcade?.adapter(forKey: "Test"))
    }
    
}
