//
//  ExpressionTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class ExpressionTests: XCTestCase {

    func testDescription() {
        XCTAssertEqual(Expression.equal("foo", "bar").description, "foo = bar")
        XCTAssertEqual(Expression.equal("foo", 1).description, "foo = 1")
        XCTAssertEqual(Expression.notEqual("foo", "bar").description, "foo != bar")
        XCTAssertEqual(Expression.comparison("foo", Comparison.equalTo, "bar").description, "foo = bar")
    }
    
    func testPredicate() {
        XCTAssertEqual(Expression.equal("foo", "bar").predicate().description, NSPredicate(format: "foo = %@", "bar").description)
    }

}
