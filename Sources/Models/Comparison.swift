//
//  Comparison.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public enum Comparison: String {
    case equalTo = "equal_to"
    case notEqualTo = "not_equal_to"
    case greaterThan = "greater_than"
    case greaterThanOrEqualTo = "greater_than_or_equal_to"
    case lessThan = "less_than"
    case lessThanOrEqualTo = "less_than_or_equal_to"
    case contains = "contains"
    case like = "like"
    case inside = "in"
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
        case .contains: return NSComparisonPredicate.Operator.contains
        case .like: return NSComparisonPredicate.Operator.like
        case .inside: return NSComparisonPredicate.Operator.in
        }        
    }
    
}

extension Comparison: CustomStringConvertible {
    public var description: String { return rawValue }
}
