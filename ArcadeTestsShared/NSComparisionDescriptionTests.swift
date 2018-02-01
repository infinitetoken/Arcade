//
//  NSComparisionDescriptionTests.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
@testable import Arcade

class NSComparisionDescriptionTests: XCTestCase {
    
    func testDescription() {
        let options: NSComparisonPredicate.Options = [.caseInsensitive, .diacriticInsensitive, .normalized]
        
        XCTAssertEqual(options.description, "cdn")
    }
    
}
