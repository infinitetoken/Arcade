//
//  Expression.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/31/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public typealias Key = String
public typealias Value = Any?

public enum Expression {
    case equal(Key, Value)
    case notEqual(Key, Value)
    case contains(Key, Value)
    case like(Key, Value)
    case inside(Key, Value)
    case comparison(Key, Comparison, Value, NSComparisonPredicate.Options)
    case isNil(Key)
    case isNotNil(Key)
    case isEmpty(Key)
    case search(Value)
    case all
}

public extension Expression {
    
    var dictionary: [String : Any] {
        switch self {
        case .equal(let key, let value):
            return [
                "key" : key,
                "comparison" : Comparison.equalTo.rawValue,
                "value": value != nil ? value! : NSNull(),
                "options": NSNull()
            ]
        case .notEqual(let key, let value):
            return [
                "key" : key,
                "comparison" : Comparison.notEqualTo.rawValue,
                "value": value != nil ? value! : NSNull(),
                "options": NSNull()
            ]
        case .contains(let key, let value):
            return [
                "key" : key,
                "comparison" : Comparison.contains.rawValue,
                "value": value != nil ? value! : NSNull(),
                "options": NSNull()
            ]
        case .like(let key, let value):
            return [
                "key" : key,
                "comparison" : Comparison.like.rawValue,
                "value": value != nil ? value! : NSNull(),
                "options": NSNull()
            ]
        case .inside(let key, let value):
            return [
                "key" : key,
                "comparison" : Comparison.inside.rawValue,
                "value": value != nil ? value! : NSNull(),
                "options": NSNull()
            ]
        case .comparison(let key, let comparison, let value, let options):
            return [
                "key" : key,
                "comparison" : comparison.rawValue,
                "value": value != nil ? value! : NSNull(),
                "options": options.description
            ]
        case .isNil(let key):
            return [
                "key" : key,
                "comparison" : Comparison.equalTo.rawValue,
                "value": NSNull(),
                "options": NSNull()
            ]
        case .isNotNil(let key):
            return [
                "key" : key,
                "comparison" : Comparison.notEqualTo.rawValue,
                "value": NSNull(),
                "options": NSNull()
            ]
        case .isEmpty(let key):
            return [
                "key" : key,
                "comparison" : "empty",
                "value": NSNull(),
                "options": NSNull()
            ]
        case .search(let value):
            return [
                "key" : NSNull(),
                "comparison" : "search",
                "value": value != nil ? value! : NSNull(),
                "options": NSNull()
            ]
        case .all:
            return [:]
        }
    }
    
}

extension Expression {
    
    public func predicate() -> NSPredicate {
        switch self {
        case let .equal(key, value): return self.comparisonPredicate(for: key, value: value, comparison: Comparison.equalTo)
        case let .notEqual(key, value): return self.comparisonPredicate(for: key, value: value, comparison: Comparison.notEqualTo)
        case let .contains(key, value): return self.comparisonPredicate(for: key, value: value, comparison: Comparison.contains)
        case let .like(key, value): return self.comparisonPredicate(for: key, value: value, comparison: Comparison.like)
        case let .inside(key, value): return self.comparisonPredicate(for: key, value: value, comparison: Comparison.inside)
        case let .comparison(key, comparison, value, options):
            let leftExpression = NSExpression(forKeyPath: key)
            let rightExpression = NSExpression(forConstantValue: value)
            let modifier = NSComparisonPredicate.Modifier.direct
            let type = comparison.type()
            return NSComparisonPredicate(leftExpression: leftExpression, rightExpression: rightExpression, modifier: modifier, type: type, options: options)
        case let .isNil(key): return NSPredicate(format: "%K = nil", key)
        case let .isNotNil(key): return NSPredicate(format: "%K != nil", key)
        case .isEmpty(_): return NSPredicate(value: true)
        case .search(_): return NSPredicate(value: true)
        case .all: return NSPredicate(value: true)
        }
    }
    
    private func comparisonPredicate(for key: Key, value: Any?, comparison: Comparison) -> NSComparisonPredicate {
        let leftExpression = NSExpression(forKeyPath: key)
        let rightExpression = NSExpression(forConstantValue: value)
        let modifier = NSComparisonPredicate.Modifier.direct
        let type = comparison.type()
        return NSComparisonPredicate(leftExpression: leftExpression, rightExpression: rightExpression, modifier: modifier, type: type, options: [])
    }
    
}

extension Expression: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case let .equal(key, value): return "\(key) \(Comparison.equalTo) \(value != nil ? value! : "nil")"
        case let .notEqual(key, value): return "\(key) \(Comparison.notEqualTo) \(value != nil ? value! : "nil")"
        case let .contains(key, value): return "\(key) \(Comparison.contains) \(value != nil ? value! : "nil")"
        case let .like(key, value): return "\(key) \(Comparison.like) \(value != nil ? value! : "nil")"
        case let .inside(key, value): return "\(key) \(Comparison.inside) \(value != nil ? value! : "nil")"
        case let .comparison(key, comparison, value, options): return options.rawValue == 0 ? "\(key) \(comparison) \(value != nil ? value! : "nil")" : "\(key) \(comparison)[\(options)] \(value != nil ? value! : "nil")"
        case let .isNil(key): return "\(key) \(Comparison.equalTo) nil"
        case let .isNotNil(key): return "\(key) \(Comparison.notEqualTo) nil"
        case let .isEmpty(key): return "\(key) empty"
        case let .search(value): return "search \(value != nil ? value! : "nil")"
        case .all: return "true"
        }
    }
    
}
