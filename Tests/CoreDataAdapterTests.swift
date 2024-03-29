//
//  CoreDataAdapterTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import XCTest
import CoreData
import Future
@testable import Arcade

class CoreDataAdapterTests: XCTestCase {

    var adapter: CoreDataAdapter? {
        guard let url = Bundle(for: CoreDataAdapterTests.self).url(forResource: "TestModel", withExtension: "momd") else { return nil }
        
        let model = NSManagedObjectModel(contentsOf: url)
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
        
        return CoreDataAdapter(persistentContainerName: "TestModel", persistentStoreDescriptions: [persistentStoreDescription], managedObjectModel: model)
    }
    
    func testCanConnect() {
        guard let adapter = self.adapter else { return }
        
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
        guard let adapter = self.adapter else { return }
        
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
        guard let adapter = self.adapter else { return }
        
        let expectation = XCTestExpectation(description: "Insert")
        
        let owner = Owner(uuid: UUID().uuidString, name: "Test")
        
        adapter.connect().then({ (success) -> Future<Owner> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).subscribe({ (owner) in
            XCTAssertNotNil(owner)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanFind() {
        guard let adapter = self.adapter else { return }
        
        let expectation = XCTestExpectation(description: "Find")

        let owner = Owner(uuid: UUID().uuidString, name: "Test")

        adapter.connect().then({ (success) -> Future<Owner> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (owner) -> Future<Owner> in
            XCTAssertNotNil(owner)
            return adapter.insert(storable: owner)
        }).then({ (owner) -> Future<Owner> in
            XCTAssertNotNil(owner)
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
        guard let adapter = self.adapter else { return }
        
        let expectation = XCTestExpectation(description: "Fetch")

        let uuid = UUID().uuidString
        let owner = Owner(uuid: uuid, name: "Test")

        let expression = Expression.equal("uuid", uuid)
        let query = Query.expression(expression, [], [])

        adapter.connect().then({ (success) -> Future<Owner> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (owner) -> Future<[Owner]> in
            XCTAssertNotNil(owner)
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
    
    func testCanSort() {
        guard let adapter = self.adapter else { return }
        
        let expectation = XCTestExpectation(description: "Sort")
        
        let owner1 = Owner(uuid: UUID().uuidString, name: "Owner 1")
        let owner2 = Owner(uuid: UUID().uuidString, name: "Owner 2")
        
        let query: Query? = nil
        let sort = Sort(key: "name", order: .descending)
        
        adapter.connect().then({ (success) -> Future<[Owner]> in
            XCTAssertTrue(success)
            return adapter.insert(storables: [owner1, owner2])
        }).then({ (owners) -> Future<[Owner]> in
            XCTAssertEqual(owners.count, 2)
            return adapter.fetch(query: query, sorts: [sort], limit: 0, offset: 0)
        }).subscribe({ (owners) in
            XCTAssertEqual(owners.count, 2)
            XCTAssertEqual(owners.first?.name, "Owner 2")
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }

    func testCanUpdate() {
        guard let adapter = self.adapter else { return }
        
        let expectation = XCTestExpectation(description: "Update")

        var owner = Owner(uuid: UUID().uuidString, name: "Test")

        adapter.connect().then({ (success) -> Future<Owner> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (owner) -> Future<Owner> in
            XCTAssertNotNil(owner)
            return adapter.find(uuid: owner.uuid)
        }).then({ (fetchedOwner) -> Future<Owner> in
            XCTAssertNotNil(fetchedOwner)

            owner.name = "Foo"

            return adapter.update(storable: owner)
        }).then({ (owner) -> Future<Owner> in
            XCTAssertNotNil(owner)
            return adapter.find(uuid: owner.uuid)
        }).subscribe({ (fetchedOwner) in
            XCTAssertEqual(fetchedOwner.name, "Foo")
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testCanDelete() {
        guard let adapter = self.adapter else { return }
        
        let expectation = XCTestExpectation(description: "Delete")

        let owner = Owner(uuid: UUID().uuidString, name: "Test")

        adapter.connect().then({ (success) -> Future<Owner> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (owner) -> Future<Bool> in
            XCTAssertNotNil(owner)
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
        guard let adapter = self.adapter else { return }
        
        let expectation = XCTestExpectation(description: "Count")

        let owner = Owner(uuid: UUID().uuidString, name: "Test")

        let expression = Expression.equal("name", "Test")
        let query = Query.expression(expression, [], [])

        adapter.connect().then({ (success) -> Future<Owner> in
            XCTAssertTrue(success)
            return adapter.insert(storable: owner)
        }).then({ (owner) -> Future<Int> in
            XCTAssertNotNil(owner)
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
