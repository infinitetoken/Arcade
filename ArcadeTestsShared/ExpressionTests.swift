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
        XCTAssertEqual(Expression.contains("foo", "bar").description, "foo contains bar")
        XCTAssertEqual(Expression.like("foo", "bar").description, "foo like bar")
        XCTAssertEqual(Expression.inside("foo", ["foo", "bar"]).description, "foo in [\"foo\", \"bar\"]")
        XCTAssertEqual(Expression.comparison("foo", Comparison.equalTo, "bar", []).description, "foo = bar")
        XCTAssertEqual(Expression.comparison("foo", Comparison.contains, "bar", [.caseInsensitive]).description, "foo contains[c] bar")
        XCTAssertEqual(Expression.isNil("foo").description, "foo = nil")
        XCTAssertEqual(Expression.isNotNil("foo").description, "foo != nil")
    }
    
    func testPredicate() {
        XCTAssertEqual(Expression.equal("foo", "bar").predicate().description, NSPredicate(format: "foo = %@", "bar").description)
        XCTAssertEqual(Expression.notEqual("foo", "bar").predicate().description, NSPredicate(format: "foo != %@", "bar").description)
        XCTAssertEqual(Expression.contains("foo", "bar").predicate().description, NSPredicate(format: "foo contains %@", "bar").description)
        XCTAssertEqual(Expression.like("foo", "bar").predicate().description, NSPredicate(format: "foo like %@", "bar").description)
        XCTAssertEqual(Expression.inside("foo", ["foo", "bar"]).predicate().description, NSPredicate(format: "foo in %@", ["foo", "bar"]).description)
        XCTAssertEqual(Expression.comparison("foo", Comparison.contains, "bar", [.caseInsensitive]).predicate().description, NSPredicate(format: "foo contains[c] %@", "bar").description)
        XCTAssertEqual(Expression.isNil("foo").predicate().description, NSPredicate(format: "foo = NULL").description)
        XCTAssertEqual(Expression.isNotNil("foo").predicate().description, NSPredicate(format: "foo != NULL").description)
    }

}
