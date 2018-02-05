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
    
    func testAll() {
        let expectation = XCTestExpectation(description: "All")
        
        let owner = Owner(uuid: UUID(), name: "Test")
        guard let adapter = owner.adapter else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save()
        }).then { (success) -> Future<[Owner]> in
            XCTAssertTrue(success)
            return Owner.all()
        }.subscribe({ (owners) in
            XCTAssertEqual(owners.count, 1)
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
        guard let adapter = owner.adapter else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save()
        }).then { (success) -> Future<[Owner]> in
            XCTAssertTrue(success)
            let query = Query.expression(Expression.equal("name", "Test"))
            return Owner.fetch(query: query)
        }.subscribe({ (owners) in
            XCTAssertEqual(owners.count, 1)
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
        guard let adapter = owner.adapter else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save()
        }).then { (success) -> Future<Owner?> in
            XCTAssertTrue(success)
            return Owner.find(uuid: owner.uuid)
        }.subscribe({ (owner) in
            XCTAssertNotNil(owner)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testSave() {
        let expectation = XCTestExpectation(description: "Save")
        
        let owner = Owner(uuid: UUID(), name: "Test")
        guard let adapter = owner.adapter else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save()
        }).then { (success) -> Future<Int> in
            XCTAssertTrue(success)
            return adapter.count(table: TestTable.owner)
        }.subscribe({ (count) in
            XCTAssertEqual(count, 1)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDelete() {
        let expectation = XCTestExpectation(description: "Delete")
        
        let owner = Owner(uuid: UUID(), name: "Test")
        guard let adapter = owner.adapter else { XCTFail(); return }
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return owner.save()
        }).then { (success) -> Future<Int> in
            XCTAssertTrue(success)
            return adapter.count(table: TestTable.owner)
        }.then({ (count) -> Future<Bool> in
            XCTAssertEqual(count, 1)
            return owner.delete()
        }).then({ (success) -> Future<Int> in
            XCTAssertTrue(success)
            return adapter.count(table: TestTable.owner)
        }).subscribe({ (count) in
            XCTAssertEqual(count, 0)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
}
