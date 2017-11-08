//
//  Comparison.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public enum Comparison: String {
    case equalTo = "="
    case notEqualTo = "!="
    case greaterThan = ">"
    case greaterThanOrEqualTo = ">="
    case lessThan = "<"
    case lessThanOrEqualTo = "<="
}

extension Comparison {
    
    public func type() -> NSComparisonPredicate.Operator {
        switch self {
        case .equalTo: return NSComparisonPredicate.Operator.equalTo
        case .notEqualTo: return NSComparisonPredicate.Operator.notEqualTo
        case .greaterThan: return NSComparisonPredicate.Operator.greaterThan
        case .greaterThanOrEqualTo: return NSComparisonPredicate.Operator.greaterThanOrEqualTo
        case .lessThan: return NSComparisonPredicate.Operator.lessThan
        case .lessThanOrEqualTo: return NSComparisonPredicate.Operator.lessThanOrEqualTo
        }
    }
    
}

extension Comparison: CustomStringConvertible {
    public var description: String { return rawValue }
}
