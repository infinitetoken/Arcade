//
//  Expression.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/31/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public typealias KeyPath = String
public typealias Constant = Any?

public enum Expression {
    case equal(KeyPath, Constant)
    case notEqual(KeyPath, Constant)
    case contains(KeyPath, Constant)
    case like(KeyPath, Constant)
    case inside(KeyPath, Constant)
    case comparison(KeyPath, Comparison, Constant, NSComparisonPredicate.Options)
    case isNil(KeyPath)
    case isNotNil(KeyPath)
    case all
}

extension Expression {
    
    public func predicate() -> NSPredicate {
        switch self {
        case let .equal(keyPath, constant): return self.comparisonPredicate(for: keyPath, constant: constant, comparison: Comparison.equalTo)
        case let .notEqual(keyPath, constant): return self.comparisonPredicate(for: keyPath, constant: constant, comparison: Comparison.notEqualTo)
        case let .contains(keyPath, constant): return self.comparisonPredicate(for: keyPath, constant: constant, comparison: Comparison.contains)
        case let .like(keyPath, constant): return self.comparisonPredicate(for: keyPath, constant: constant, comparison: Comparison.like)
        case let .inside(keyPath, constant): return self.comparisonPredicate(for: keyPath, constant: constant, comparison: Comparison.inside)
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
    
    private func comparisonPredicate(for keyPath: KeyPath, constant: Any?, comparison: Comparison) -> NSComparisonPredicate {
        let leftExpression = NSExpression(forKeyPath: keyPath)
        let rightExpression = NSExpression(forConstantValue: constant)
        let modifier = NSComparisonPredicate.Modifier.direct
        let type = comparison.type()
        return NSComparisonPredicate(leftExpression: leftExpression, rightExpression: rightExpression, modifier: modifier, type: type, options: [])
    }
    
}

extension Expression: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case let .equal(keyPath, constant): return "\(keyPath) \(Comparison.equalTo) \(constant != nil ? constant! : "nil")"
        case let .notEqual(keyPath, constant): return "\(keyPath) \(Comparison.notEqualTo) \(constant != nil ? constant! : "nil")"
        case let .contains(keyPath, constant): return "\(keyPath) \(Comparison.contains) \(constant != nil ? constant! : "nil")"
        case let .like(keyPath, constant): return "\(keyPath) \(Comparison.like) \(constant != nil ? constant! : "nil")"
        case let .inside(keyPath, constant): return "\(keyPath) \(Comparison.inside) \(constant != nil ? constant! : "nil")"
        case let .comparison(keyPath, comparison, constant, options): return options.rawValue == 0 ? "\(keyPath) \(comparison) \(constant != nil ? constant! : "nil")" : "\(keyPath) \(comparison)[\(options)] \(constant != nil ? constant! : "nil")"
        case let .isNil(keyPath): return "\(keyPath) \(Comparison.equalTo) nil"
        case let .isNotNil(keyPath): return "\(keyPath) \(Comparison.notEqualTo) nil"
        case .all: return "true"
        }
    }
    
}
