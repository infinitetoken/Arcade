//
//  FutureTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

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
    
}
