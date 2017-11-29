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
    case contains(KeyPath, Constant)
    case comparison(KeyPath, Comparison, Constant, NSComparisonPredicate.Options)
    case isNil(KeyPath)
    case isNotNil(KeyPath)
    case all
}

extension Expression {
    public func predicate() -> NSPredicate {
        switch self {
            case let .equal(keyPath, constant): return NSPredicate(format: "%K = %@", keyPath, constant.description)
            case let .notEqual(keyPath, constant): return NSPredicate(format: "%K != %@", keyPath, constant.description)
            case let .contains(keypath, constant): return NSPredicate(format: "%K contains %@", keypath, constant.description)
            case let .comparison(keyPath, comparison, constant, options):
                let leftExpression = NSExpression(forKeyPath: keyPath)
                let rightExpression = NSExpression(forConstantValue: constant)
                let modifier = NSComparisonPredicate.Modifier.direct
                let type = comparison.type()
                return NSComparisonPredicate(leftExpression: leftExpression, rightExpression: rightExpression, modifier: modifier, type: type, options: options)
            case let .isNil(keyPath): return NSPredicate(format: "%K = nil", keyPath)
            case let .isNotNil(keyPath): return NSPredicate(format: "%K != nil", keyPath)
            case .all: return NSPredicate(value: true)
        }
    }
}

extension Expression: CustomStringConvertible {
    public var description: String {
        switch self {
            case let .equal(keyPath, constant): return "\(keyPath) \(Comparison.equalTo) \(constant)"
            case let .notEqual(keyPath, constant): return "\(keyPath) \(Comparison.notEqualTo) \(constant)"
            case let .contains(keyPath, constant): return "\(keyPath) \(Comparison.contains) \(constant)"
        case let .comparison(keyPath, comparison, constant, options): return options.rawValue == 0 ? "\(keyPath) \(comparison) \(constant)" : "\(keyPath) \(comparison)[\(options)] \(constant)"
            case let .isNil(keyPath): return "\(keyPath) \(Comparison.equalTo) nil"
            case let .isNotNil(keyPath): return "\(keyPath) \(Comparison.notEqualTo) nil"
            case .all: return "true"
        }
    }
}
