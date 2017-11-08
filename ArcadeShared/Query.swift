//
//  Query.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/31/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public enum Query {
    case expression(Expression)
    case and([Expression])
    case or([Expression])
}

public extension Query {
    public func predicate() -> NSPredicate {
        switch self {
        case let .expression(exp): return exp.predicate()
        case let .and(exps): return NSCompoundPredicate.init(andPredicateWithSubpredicates: exps.map { $0.predicate() })
        case let .or(exps): return NSCompoundPredicate.init(orPredicateWithSubpredicates: exps.map { $0.predicate() })
        }
    }
}

extension Query: CustomStringConvertible {
    public var description: String {
        switch self {
            case let .expression(exp): return exp.description
            case let .and(exps): return exps.map { $0.description }.joined(separator: " && ")
            case let .or(exps): return exps.map { $0.description }.joined(separator: " || ")
        }
    }
}
