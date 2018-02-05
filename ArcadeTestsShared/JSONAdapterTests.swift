//
//  JSONAdapterTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/17/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class JSONAdapterTests: XCTestCase {
    
    var adapter: JSONAdapter {
        let directory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
        
        return JSONAdapter(directory: directory)
    }
    
    func testCanConnect() {
        let adapter = self.adapter
        let expectation = XCTestExpectation(description: "Connect")
        
        adapter.connect().subscribe({ (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanDisconnect() {
        let adapter = self.adapter
        let expectation = XCTestExpectation(description: "Disconnect")
        
        adapter.disconnect().subscribe({ (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanInsert() {
        let adapter = self.adapter
        let expectation = XCTestExpectation(description: "Insert")
        
        let owner = Owner(uuid: UUID(), name: "Test")
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).subscribe({ (success) in
            XCTAssertTrue(success)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanFind() {
        let adapter = self.adapter
        let expectation = XCTestExpectation(description: "Find")
        
        let owner = Owner(uuid: UUID(), name: "Test")
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (success) -> Future<Owner?> in
            XCTAssertTrue(success)
            return adapter.find(uuid: owner.uuid)
        }).subscribe({ (owner) in
            XCTAssertNotNil(owner)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanFetch() {
        let adapter = self.adapter
        let expectation = XCTestExpectation(description: "Fetch")
        
        let uuid = UUID()
        let owner = Owner(uuid: uuid, name: "Test")
        
        let expression = Expression.equal("uuid", uuid)
        let query = Query.expression(expression)
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (success) -> Future<[Owner]> in
            XCTAssertTrue(success)
            return adapter.fetch(query: query)
        }).subscribe({ (owners) in
            XCTAssertEqual(owners.count, 1)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanUpdate() {
        let adapter = self.adapter
        let expectation = XCTestExpectation(description: "Update")
        
        var owner = Owner(uuid: UUID(), name: "Test")
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (success) -> Future<Owner?> in
            XCTAssertTrue(success)
            return adapter.find(uuid: owner.uuid)
        }).then({ (fetchedOwner) -> Future<Bool> in
            XCTAssertNotNil(fetchedOwner)
            
            owner.name = "Foo"
            
            return adapter.update(storable: owner)
        }).then({ (success) -> Future<Owner?> in
            XCTAssertTrue(success)
            return adapter.find(uuid: owner.uuid)
        }).subscribe({ (fetchedOwner) in
            XCTAssertNotNil(fetchedOwner)
            XCTAssertEqual(fetchedOwner?.name, "Foo")
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanDelete() {
        let adapter = self.adapter
        let expectation = XCTestExpectation(description: "Delete")
        
        let owner = Owner(uuid: UUID(), name: "Test")
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return adapter.delete(uuid: owner.uuid, type: Owner.self)
        }).then({ (success) -> Future<Int> in
            XCTAssertTrue(success)
            return adapter.count(table: TestTable.owner, query: nil)
        }).subscribe({ (count) in
            XCTAssertEqual(count, 0)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanCount() {
        let adapter = self.adapter
        let expectation = XCTestExpectation(description: "Count")
        
        let owner = Owner(uuid: UUID(), name: "Test")
        
        let expression = Expression.equal("name", "Test")
        let query = Query.expression(expression)
        
        adapter.connect().then({ (success) -> Future<Bool> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (success) -> Future<Int> in
            XCTAssertTrue(success)
            return adapter.count(table: TestTable.owner, query: query)
        }).subscribe({ (count) in
            XCTAssertEqual(count, 1)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
}
