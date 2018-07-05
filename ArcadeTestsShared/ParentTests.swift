//
//  ParentTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class ParentTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        Arcade.shared.addAdapter(InMemoryAdapter(), forKey: "Test")
    }
    
    override func tearDown() {
        super.tearDown()
        
        Arcade.shared.removeAdapter(forKey: "Test")
    }
    
    func testFind() {
        let expectation = XCTestExpectation(description: "Find")
        
        let owner = Owner(uuid: UUID().uuidString, name: "Test")
        let pet = Pet(uuid: UUID().uuidString, name: "Test", ownerID: owner.uuid)
        
        guard let adapter = Arcade.shared.adapter(forKey: "Test") else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save(adapter: adapter)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return pet.save(adapter: adapter)
        }).then { (success) -> Future<Owner?> in
            XCTAssertTrue(success)
            return pet.owner.find(adapter: adapter)
        }.subscribe({ (owner) in
            XCTAssertNotNil(owner)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
}
