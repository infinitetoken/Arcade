//
//  FutureTests.swift
//  Future
//
//  Created by Aaron Wright on 8/17/18.
//  Copyright © 2018 Aaron Wright. All rights reserved.
//

import XCTest
@testable import Future

enum FutureTestError: Error {
    case error
}

class FutureTests: XCTestCase {
    
    func testSuccess() {
        let future = Future<Int>(1)
        
        let expectation = XCTestExpectation(description: "Future")
        
        future.subscribe({ (value) in
            expectation.fulfill()
            XCTAssertEqual(value, 1)
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFailure() {
        let future = Future<Int>(FutureTestError.error)
        
        let expectation = XCTestExpectation(description: "Future")
        
        future.subscribe({ (value) in
            XCTFail()
        }) { (error) in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAlways() {
        let future = Future<Int>(1)

        let expectation = XCTestExpectation(description: "Future")

        future.subscribe({ (value) in
            XCTAssertEqual(value, 1)
        }, { (error) in
            XCTFail(error.localizedDescription)
        }, always: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTransform() {
        let future = Future<String>("TEST")
        
        let expectation = XCTestExpectation(description: "Future")
        
        future.transform({ (value) -> String in
            return value.lowercased()
        }).subscribe({ (value) in
            expectation.fulfill()
            XCTAssertEqual(value, "test")
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testThen() {
        let future = Future<String>("TEST")
        
        let expectation = XCTestExpectation(description: "Future")
        
        future.then({ (value) -> Future<Int> in
            return Future<Int>(value.lengthOfBytes(using: String.Encoding.utf8))
        }).subscribe({ (count) in
            expectation.fulfill()
            XCTAssertEqual(count, 4)
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConditionalThen() {
        let future = Future<String>("TEST")
        
        let expectation = XCTestExpectation(description: "Future")
        
        future.then(condition: false, ifTrue: { (value) -> Future<(Int?, Bool?)> in
            Future((value.lengthOfBytes(using: String.Encoding.utf8), nil))
        }) { (value) -> Future<(Int?, Bool?)> in
            Future((nil, true))
        }.subscribe({ (values) in
            expectation.fulfill()
            XCTAssert(values.1!)
            XCTAssertNil(values.0)
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        future.then(condition: true, ifTrue: { (value) -> Future<(Int?, Bool?)> in
            Future((value.lengthOfBytes(using: String.Encoding.utf8), nil))
        }) { (value) -> Future<(Int?, Bool?)> in
            Future((nil, true))
        }.subscribe({ (values) in
            expectation.fulfill()
            XCTAssertEqual(values.0, 4)
            XCTAssertNil(values.1)
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        future.then(condition: false, ifTrue: { (value) -> Future<Int?> in
            Future(value.lengthOfBytes(using: String.Encoding.utf8))
        }) { (value) -> Future<Int?> in
            Future(nil)
        }.subscribe({ (value) in
            expectation.fulfill()
            XCTAssertNil(value)
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        future.then(condition: true, ifTrue: { (value) -> Future<Int?> in
            Future(value.lengthOfBytes(using: String.Encoding.utf8))
        }) { (value) -> Future<Int?> in
            Future(nil)
        }.subscribe({ (value) in
            expectation.fulfill()
            XCTAssertEqual(value, 4)
        }) { (error) in
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
}

