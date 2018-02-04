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
    
    var adapter: JSONAdapter!
    var uuid: UUID = UUID()
    var directory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
    
    override func setUp() {
        super.setUp()
        
        self.adapter = JSONAdapter(directory: self.directory)
        
        let expectation = XCTestExpectation(description: "Setup")
        
        self.adapter.connect().subscribe({ (adapter) in
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    override func tearDown() {
        let expectation = XCTestExpectation(description: "Teardown")
        
        self.adapter.disconnect().subscribe({ (adapter) in
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

        self.adapter.connect().subscribe({ (adapter) in
            expectation.fulfill()
        }) { (error) in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanDisconnect() {
        let expectation = XCTestExpectation(description: "Disconnect")
        
        self.adapter.disconnect().subscribe({ (adapter) in
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
        
        self.adapter.insert(storable: widget).subscribe({ (adapter) in
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
        
        self.adapter.insert(storable: widget).then({ (result) -> Future<Widget?> in
            return self.adapter.find(uuid: widget.uuid)
        }).subscribe({ (widget) in
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
        
        let uuid = UUID()
        let widget = Widget(uuid: uuid, name: "Test")
        
        let expression = Expression.equal("uuid", uuid)
        let query = Query.expression(expression)
        
        self.adapter.insert(storable: widget).then({ (result) -> Future<[Widget]> in
            return self.adapter.fetch(query: query)
        }).subscribe({ (widgets) in
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
        
        self.adapter.insert(storable: widget).then({ (result) -> Future<Widget?> in
            return self.adapter.find(uuid: widget.uuid)
        }).then({ (fetchedWidget) -> Future<Bool> in
            XCTAssertNotNil(fetchedWidget)
            
            widget.name = "Foo"
            
            return self.adapter.update(storable: widget)
        }).then({ (result) -> Future<Widget?> in
            return self.adapter.find(uuid: widget.uuid)
        }).subscribe({ (fetchedWidget) in
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
        
        self.adapter.insert(storable: widget).then({ (adapter) -> Future<Bool> in
            return self.adapter.delete(uuid: widget.uuid, type: Widget.self)
        }).then({ (result) -> Future<Int> in
            return self.adapter.count(table: TestTable.widget, query: nil)
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
        let expectation = XCTestExpectation(description: "Count")
        
        let widget = Widget(uuid: UUID(), name: "Test")
        
        let expression = Expression.equal("name", "Test")
        let query = Query.expression(expression)
        
        self.adapter.insert(storable: widget).then({ (result) -> Future<Int> in
            return self.adapter.count(table: TestTable.widget, query: query)
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
