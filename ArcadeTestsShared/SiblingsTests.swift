//
//  SiblingsTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
import Future
@testable import Arcade

class SiblingsTests: XCTestCase {
    
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
        
        let pet = Pet(uuid: UUID().uuidString, name: "Test", ownerID: nil)
        let toy = Toy(uuid: UUID().uuidString, name: "Test")
        let petToy = PetToy(uuid: UUID().uuidString, petID: pet.uuid, toyID: toy.uuid)
        
        guard let adapter = Arcade.shared.adapter(forKey: "Test") else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return pet.save(adapter: adapter)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return toy.save(adapter: adapter)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return petToy.save(adapter: adapter)
        }).then { (success) -> Future<[Toy]> in
            XCTAssertTrue(success)
            return pet.toys.all(adapter: adapter)
        }.subscribe({ (toys) in
            XCTAssertEqual(toys.count, 1)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFetch() {
        let expectation = XCTestExpectation(description: "Fetch")
        
        let pet = Pet(uuid: UUID().uuidString, name: "Test", ownerID: nil)
        let toy = Toy(uuid: UUID().uuidString, name: "Test")
        let petToy = PetToy(uuid: UUID().uuidString, petID: pet.uuid, toyID: toy.uuid)
        
        guard let adapter = Arcade.shared.adapter(forKey: "Test") else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return pet.save(adapter: adapter)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return toy.save(adapter: adapter)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return petToy.save(adapter: adapter)
        }).then { (success) -> Future<[Toy]> in
            XCTAssertTrue(success)
            let query = Query.expression(Expression.equal("name", "Test"))
            return pet.toys.fetch(query: query, adapter: adapter)
        }.subscribe({ (toys) in
            XCTAssertEqual(toys.count, 1)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFind() {
        let expectation = XCTestExpectation(description: "Find")
        
        let pet = Pet(uuid: UUID().uuidString, name: "Test", ownerID: nil)
        let toy = Toy(uuid: UUID().uuidString, name: "Test")
        let petToy = PetToy(uuid: UUID().uuidString, petID: pet.uuid, toyID: toy.uuid)
        
        guard let adapter = Arcade.shared.adapter(forKey: "Test") else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return pet.save(adapter: adapter)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return toy.save(adapter: adapter)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return petToy.save(adapter: adapter)
        }).then { (success) -> Future<Toy?> in
            XCTAssertTrue(success)
            return pet.toys.find(uuid: toy.uuid, adapter: adapter)
        }.subscribe({ (toy) in
            XCTAssertNotNil(toy)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
}
