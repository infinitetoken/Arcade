//
//  Expression.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/31/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public typealias KeyPath = String
public typealias Constant = CustomStringConvertible

public enum Expression {
    case equal(KeyPath, Constant)
    case notEqual(KeyPath, Constant)
    case comparison(KeyPath, Comparison, Constant)
    case isNil(KeyPath)
    case isNotNil(KeyPath)
}

extension Expression {
    public func predicate() -> NSPredicate {
        switch self {
            case let .equal(keyPath, constant): return NSPredicate(format: "%K = %@", keyPath, constant.description)
            case let .notEqual(keyPath, constant): return NSPredicate(format: "%K != %@", keyPath, constant.description)
            case let .comparison(keyPath, comparison, constant):
                let leftExpression = NSExpression(forKeyPath: keyPath)
                let rightExpression = NSExpression(forConstantValue: constant)
                let modifier = NSComparisonPredicate.Modifier.direct
                let type = comparison.type()
                return NSComparisonPredicate(leftExpression: leftExpression, rightExpression: rightExpression, modifier: modifier, type: type, options: [])
            case let .isNil(keyPath): return NSPredicate(format: "%K = nil", keyPath)
            case let .isNotNil(keyPath): return NSPredicate(format: "%K != nil", keyPath)
        }
    }
}

extension Expression: CustomStringConvertible {
    public var description: String {
        switch self {
            case let .equal(keyPath, constant): return "\(keyPath) \(Comparison.equalTo) \(constant)"
            case let .notEqual(keyPath, constant): return "\(keyPath) \(Comparison.notEqualTo) \(constant)"
            case let .comparison(keyPath, comparison, constant): return "\(keyPath) \(comparison) \(constant)"
            case let .isNil(keyPath): return "\(keyPath) \(Comparison.equalTo) nil"
            case let .isNotNil(keyPath): return "\(keyPath) \(Comparison.notEqualTo) nil"
        }
    }
}
