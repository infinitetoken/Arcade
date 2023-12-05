//
//  QueryTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class QueryTests: XCTestCase {
    
    var one: Expression!
    var two: Expression!
    
    override func setUp() {
        super.setUp()
        
        self.one = Expression.equal("foo", "bar")
        self.two = Expression.equal("foo", "bar")
    }
    
    override func tearDown() {
        self.one = nil
        self.two = nil
        super.tearDown()
    }

    func testDescription() {
        XCTAssertEqual(Query.expression(self.one, [], []).description, "foo equal_to bar")
        XCTAssertEqual(Query.and([self.one, self.two], [], []).description, "foo equal_to bar && foo equal_to bar")
        XCTAssertEqual(Query.or([self.one, self.two], [], []).description, "foo equal_to bar || foo equal_to bar")
        XCTAssertEqual(Query.compoundAnd([Query.expression(self.one, [], []), Query.expression(self.two, [], [])], [], []).description, "(foo equal_to bar) && (foo equal_to bar)")
        XCTAssertEqual(Query.compoundOr([Query.expression(self.one, [], []), Query.expression(self.two, [], [])], [], []).description, "(foo equal_to bar) || (foo equal_to bar)")
    }
    
    func testPredicate() {
        let predicateOne = NSPredicate(format: "foo = %@", "bar")
        let predicateTwo = NSPredicate(format: "foo = %@", "bar")
        
        XCTAssertEqual(Query.expression(self.one, [], []).predicate().description, predicateOne.description)
        XCTAssertEqual(Query.and([self.one, self.two], [], []).predicate().description, NSCompoundPredicate(andPredicateWithSubpredicates: [predicateOne, predicateTwo]).description)
        XCTAssertEqual(Query.or([self.one, self.two], [], []).predicate().description, NSCompoundPredicate(orPredicateWithSubpredicates: [predicateOne, predicateTwo]).description)
        XCTAssertEqual(Query.compoundAnd([Query.expression(self.one, [], []), Query.expression(self.two, [], [])], [], []).predicate().description, NSCompoundPredicate(andPredicateWithSubpredicates: [predicateOne, predicateTwo]).description)
        XCTAssertEqual(Query.compoundOr([Query.expression(self.one, [], []), Query.expression(self.two, [], [])], [], []).predicate().description, NSCompoundPredicate(orPredicateWithSubpredicates: [predicateOne, predicateTwo]).description)
    }

}
