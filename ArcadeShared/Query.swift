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
    case compoundAnd([Query])
    case compoundOr([Query])
}

public extension Query {
 
    public var dictionary: [String : Any] {
        switch self {
        case .expression(let expression):
            return ["expression" : expression.dictionary]
        case .and(let expressions):
            return ["and" : expressions.map { $0.dictionary }]
        case .or(let expressions):
            return ["or" : expressions.map { $0.dictionary }]
        case .compoundAnd(let queries):
            return ["and" : queries.map { $0.dictionary }]
        case .compoundOr(let queries):
            return ["or" : queries.map { $0.dictionary }]
        }
    }
    
}

public extension Query {
    
    public func predicate() -> NSPredicate {
        switch self {
        case let .expression(exp): return exp.predicate()
        case let .and(exps): return NSCompoundPredicate.init(andPredicateWithSubpredicates: exps.map { $0.predicate() })
        case let .or(exps): return NSCompoundPredicate.init(orPredicateWithSubpredicates: exps.map { $0.predicate() })
        case let .compoundAnd(queries): return NSCompoundPredicate.init(andPredicateWithSubpredicates: queries.map { $0.predicate() })
        case let .compoundOr(queries): return NSCompoundPredicate.init(orPredicateWithSubpredicates: queries.map { $0.predicate() })
        }
    }
    
}

public extension Query {
    
    public func evaluate(with storable: Storable) -> Bool {
        return self.predicate().evaluate(with: storable.dictionary)
    }
    
}

extension Query: CustomStringConvertible {
    
    public var description: String {
        switch self {
            case let .expression(exp): return exp.description
            case let .and(exps): return exps.map { $0.description }.joined(separator: " && ")
            case let .or(exps): return exps.map { $0.description }.joined(separator: " || ")
            case let .compoundAnd(queries): return queries.map { "(\($0.description))" }.joined(separator: " && ")
            case let .compoundOr(queries): return queries.map { "(\($0.description))" }.joined(separator: " || ")
        }
    }
    
}
