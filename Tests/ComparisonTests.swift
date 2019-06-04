//
//  ComparisonTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class ComparisonTests: XCTestCase {

    func testDescription() {
        XCTAssertEqual(Comparison.equalTo.description, "equal_to")
        XCTAssertEqual(Comparison.notEqualTo.description, "not_equal_to")
        XCTAssertEqual(Comparison.greaterThan.description, "greater_than")
        XCTAssertEqual(Comparison.greaterThanOrEqualTo.description, "greater_than_or_equal_to")
        XCTAssertEqual(Comparison.lessThan.description, "less_than")
        XCTAssertEqual(Comparison.lessThanOrEqualTo.description, "less_than_or_equal_to")
        XCTAssertEqual(Comparison.contains.description, "contains")
        XCTAssertEqual(Comparison.like.description, "like")
        XCTAssertEqual(Comparison.inside.description, "in")
    }
    
    func testType() {
        XCTAssertEqual(Comparison.equalTo.type(), NSComparisonPredicate.Operator.equalTo)
        XCTAssertEqual(Comparison.notEqualTo.type(), NSComparisonPredicate.Operator.notEqualTo)
        XCTAssertEqual(Comparison.greaterThan.type(), NSComparisonPredicate.Operator.greaterThan)
        XCTAssertEqual(Comparison.greaterThanOrEqualTo.type(), NSComparisonPredicate.Operator.greaterThanOrEqualTo)
        XCTAssertEqual(Comparison.lessThan.type(), NSComparisonPredicate.Operator.lessThan)
        XCTAssertEqual(Comparison.lessThanOrEqualTo.type(), NSComparisonPredicate.Operator.lessThanOrEqualTo)
        XCTAssertEqual(Comparison.contains.type(), NSComparisonPredicate.Operator.contains)
        XCTAssertEqual(Comparison.like.type(), NSComparisonPredicate.Operator.like)
        XCTAssertEqual(Comparison.inside.type(), NSComparisonPredicate.Operator.in)
    }

}
