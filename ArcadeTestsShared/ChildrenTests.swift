//
//  ChildrenTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class ChildrenTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        Arcade.shared.addAdapter(InMemoryAdapter(), forKey: "Test")
    }
    
    override func tearDown() {
        super.tearDown()
        
        Arcade.shared.removeAdapter(forKey: "Test")
    }
    
    func testAll() {
        let expectation = XCTestExpectation(description: "All")
        
        let owner = Owner(uuid: UUID().uuidString, name: "Test")
        let pet = Pet(uuid: UUID().uuidString, name: "Test", ownerID: owner.uuid)
        
        guard let adapter = Arcade.shared.adapter(forKey: "Test") else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save(adapter: adapter)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return pet.save(adapter: adapter)
        }).then { (success) -> Future<[Pet]> in
            XCTAssertTrue(success)
            return owner.pets.all(adapter: adapter)
        }.subscribe({ (pets) in
            XCTAssertEqual(pets.count, 1)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFetch() {
        let expectation = XCTestExpectation(description: "Fetch")
        
        let owner = Owner(uuid: UUID().uuidString, name: "Test")
        let pet = Pet(uuid: UUID().uuidString, name: "Test", ownerID: owner.uuid)
        
        guard let adapter = Arcade.shared.adapter(forKey: "Test") else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save(adapter: adapter)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return pet.save(adapter: adapter)
        }).then { (success) -> Future<[Pet]> in
            XCTAssertTrue(success)
            let query = Query.expression(Expression.equal("name", "Test"))
            return owner.pets.fetch(query: query, adapter: adapter)
        }.subscribe({ (pets) in
            XCTAssertEqual(pets.count, 1)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
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
        }).then { (success) -> Future<Pet?> in
            XCTAssertTrue(success)
            return owner.pets.find(uuid: pet.uuid, adapter: adapter)
        }.subscribe({ (pet) in
            XCTAssertNotNil(pet)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
}
