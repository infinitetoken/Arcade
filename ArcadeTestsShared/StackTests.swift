//
//  StackTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class StackTests: XCTestCase {
    
    var stack: Stack?
    
    override func setUp() {
        super.setUp()
        
        self.stack = Stack()
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.stack = nil
    }
    
    func testCanPush() {
        let operation = Stack.Operation(method: .insert, storables: [], table: TestTable.widget)
        
        self.stack?.push(operation)
        
        XCTAssertEqual(self.stack?.count, 1)
    }
    
    func testCanPop() {
        let operation = Stack.Operation(method: .insert, storables: [], table: TestTable.widget)
        
        self.stack?.push(operation)
        
        XCTAssertEqual(self.stack?.count, 1)
        
        let _ = self.stack?.pop()
        
        XCTAssertEqual(self.stack?.count, 0)
    }
    
    func testCanPeek() {
        let operation = Stack.Operation(method: .insert, storables: [], table: TestTable.widget)
        
        self.stack?.push(operation)
        
        XCTAssertEqual(self.stack?.count, 1)
        
        let _ = self.stack?.peek()
        
        XCTAssertEqual(self.stack?.count, 1)
    }
    
}
