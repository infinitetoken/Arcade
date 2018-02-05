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
        
        let owner = Owner(uuid: UUID(), name: "Test")
        let pet = Pet(uuid: UUID(), name: "Test", ownerID: owner.uuid)
        
        guard let adapter = owner.adapter else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save()
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return pet.save()
        }).then { (success) -> Future<[Pet]> in
            XCTAssertTrue(success)
            return owner.pets.all()
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
        
        let owner = Owner(uuid: UUID(), name: "Test")
        let pet = Pet(uuid: UUID(), name: "Test", ownerID: owner.uuid)
        
        guard let adapter = owner.adapter else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save()
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return pet.save()
        }).then { (success) -> Future<[Pet]> in
            XCTAssertTrue(success)
            let query = Query.expression(Expression.equal("name", "Test"))
            return owner.pets.fetch(query: query)
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
        
        let owner = Owner(uuid: UUID(), name: "Test")
        let pet = Pet(uuid: UUID(), name: "Test", ownerID: owner.uuid)
        
        guard let adapter = owner.adapter else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save()
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return pet.save()
        }).then { (success) -> Future<Pet?> in
            XCTAssertTrue(success)
            return owner.pets.find(uuid: pet.uuid)
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
