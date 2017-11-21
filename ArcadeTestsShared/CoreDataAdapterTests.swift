//
//  CoreDataAdapterTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class CoreDataAdapterTests: XCTestCase {

    var adapter: CoreDataAdapter!
    
    override func setUp() {
        super.setUp()
        
        let url = Bundle(for: CoreDataAdapterTests.self).url(forResource: "Model", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOf: url!)
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
        
        self.adapter = CoreDataAdapter(persistentContainerName: "Model", persistentStoreDescriptions: [persistentStoreDescription], managedObjectModel: model)
        
        let expectation = XCTestExpectation(description: "Setup")
        
        self.adapter.connect().subscribe(onNext: { (adapter) in
            self.adapter = adapter
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    override func tearDown() {
        let expectation = XCTestExpectation(description: "Teardown")
        
        self.adapter.disconnect().subscribe(onNext: { (adapter) in
            self.adapter = adapter
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        self.adapter = nil
        
        super.tearDown()
    }
    
    func testCanInitialize() {
        XCTAssertNotNil(self.adapter)
    }
    
    func testCanConnect() {
        let expectation = XCTestExpectation(description: "Connect")
        
        self.adapter.connect().subscribe(onNext: { (adapter) in
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanDisconnect() {
        let expectation = XCTestExpectation(description: "Disconnect")
        
        self.adapter.disconnect().subscribe(onNext: { (adapter) in
            XCTAssertNotNil(adapter)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanInsert() {
        let expectation = XCTestExpectation(description: "Insert")
        
        let widget = Widget(uuid: UUID(), name: "Test")
        
        self.adapter.insert(table: WidgetTable.widget, storable: widget).subscribe(onNext: { (adapter) in
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanFind() {
        let expectation = XCTestExpectation(description: "Find")
        
        let widget = Widget(uuid: UUID(), name: "Test")
        
        self.adapter.insert(table: WidgetTable.widget, storable: widget).flatMap({ (adapter) -> Future<Widget?> in
            return adapter.find(table: WidgetTable.widget, uuid: widget.uuid)
        }).subscribe(onNext: { (widget) in
            XCTAssertNotNil(widget)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanFetch() {
        let expectation = XCTestExpectation(description: "Fetch")
        
        let widget = Widget(uuid: UUID(), name: "Test")
        
        let expression = Expression.equal("name", "Test")
        let query = Query.expression(expression)
        
        self.adapter.insert(table: WidgetTable.widget, storable: widget).flatMap({ (adapter) -> Future<[Widget]> in
            return adapter.fetch(table: WidgetTable.widget, query: query)
        }).subscribe(onNext: { (widgets) in
            XCTAssertEqual(widgets.count, 1)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanUpdate() {
        let expectation = XCTestExpectation(description: "Update")
        
        var widget = Widget(uuid: UUID(), name: "Test")
        
        self.adapter.insert(table: WidgetTable.widget, storable: widget).flatMap({ (newAdapter) -> Future<Widget?> in
            self.adapter = newAdapter
            return self.adapter.find(table: WidgetTable.widget, uuid: widget.uuid)
        }).flatMap({ (fetchedWidget) -> Future<CoreDataAdapter> in
            XCTAssertNotNil(fetchedWidget)
            
            widget.name = "Foo"
            
            return self.adapter.update(table: WidgetTable.widget, storable: widget)
        }).flatMap({ (adapter) -> Future<Widget?> in
            return adapter.find(table: WidgetTable.widget, uuid: widget.uuid)
        }).subscribe(onNext: { (fetchedWidget) in
            XCTAssertNotNil(fetchedWidget)
            XCTAssertEqual(fetchedWidget?.name, "Foo")
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanDelete() {
        let expectation = XCTestExpectation(description: "Delete")
        
        let widget = Widget(uuid: UUID(), name: "Test")
        
        self.adapter.insert(table: WidgetTable.widget, storable: widget).flatMap({ (adapter) -> Future<CoreDataAdapter> in
            return adapter.delete(table: WidgetTable.widget, storable: widget)
        }).flatMap({ (adapter) -> Future<Int> in
            return adapter.count(table: WidgetTable.widget, query: nil)
        }).subscribe(onNext: { (count) in
            XCTAssertEqual(count, 0)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanCount() {
        let expectation = XCTestExpectation(description: "Count")
        
        let widget = Widget(uuid: UUID(), name: "Test")
        
        let expression = Expression.equal("name", "Test")
        let query = Query.expression(expression)
        
        self.adapter.insert(table: WidgetTable.widget, storable: widget).flatMap({ (adapter) -> Future<Int> in
            return adapter.count(table: WidgetTable.widget, query: query)
        }).subscribe(onNext: { (count) in
            XCTAssertEqual(count, 1)
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
}
