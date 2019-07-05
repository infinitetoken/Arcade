//
//  Query.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/31/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public enum Query {
    public typealias Join = Table
    public typealias Include = Table
    
    case expression(Expression, [Join], [Include])
    case and([Expression], [Join], [Include])
    case or([Expression], [Join], [Include])
    case compoundAnd([Query], [Join], [Include])
    case compoundOr([Query], [Join], [Include])
}

public extension Query {
 
    var dictionary: [String : Any] {
        switch self {
        case .expression(let expression, let joins, let includes):
            return ["expression" : expression.dictionary, "joins" : joins.map { $0.name }, "includes" : includes.map { $0.name }]
        case .and(let expressions, let joins, let includes):
            return ["and" : expressions.map { $0.dictionary }, "joins" : joins.map { $0.name }, "includes" : includes.map { $0.name }]
        case .or(let expressions, let joins, let includes):
            return ["or" : expressions.map { $0.dictionary }, "joins" : joins.map { $0.name }, "includes" : includes.map { $0.name }]
        case .compoundAnd(let queries, let joins, let includes):
            return ["and" : queries.map { $0.dictionary }, "joins" : joins.map { $0.name }, "includes" : includes.map { $0.name }]
        case .compoundOr(let queries, let joins, let includes):
            return ["or" : queries.map { $0.dictionary }, "joins" : joins.map { $0.name }, "includes" : includes.map { $0.name }]
        }
    }
    
}

public extension Query {
    
    func predicate() -> NSPredicate {
        switch self {
        case let .expression(exp, _, _): return exp.predicate()
        case let .and(exps, _, _): return NSCompoundPredicate.init(andPredicateWithSubpredicates: exps.map { $0.predicate() })
        case let .or(exps, _, _): return NSCompoundPredicate.init(orPredicateWithSubpredicates: exps.map { $0.predicate() })
        case let .compoundAnd(queries, _, _): return NSCompoundPredicate.init(andPredicateWithSubpredicates: queries.map { $0.predicate() })
        case let .compoundOr(queries, _, _): return NSCompoundPredicate.init(orPredicateWithSubpredicates: queries.map { $0.predicate() })
        }
    }
    
}

public extension Query {
    
    func evaluate(with viewable: Viewable) -> Bool {
        return self.predicate().evaluate(with: viewable.dictionary)
    }
    
}

extension Query: CustomStringConvertible {
    
    public var description: String {
        switch self {
            case let .expression(exp, joins, includes): return exp.description + " Joins: \(joins.map { $0.name }.joined(separator: ","))" + " Includes: \(includes.map { $0.name }.joined(separator: ","))"
            case let .and(exps, joins, includes): return exps.map { $0.description }.joined(separator: " && ") + " Joins: \(joins.map { $0.name }.joined(separator: ","))" + " Includes: \(includes.map { $0.name }.joined(separator: ","))"
            case let .or(exps, joins, includes): return exps.map { $0.description }.joined(separator: " || ") + " Joins: \(joins.map { $0.name }.joined(separator: ","))" + " Includes: \(includes.map { $0.name }.joined(separator: ","))"
            case let .compoundAnd(queries, joins, includes): return queries.map { "(\($0.description))" }.joined(separator: " && ") + " Joins: \(joins.map { $0.name }.joined(separator: ","))" + " Includes: \(includes.map { $0.name }.joined(separator: ","))"
            case let .compoundOr(queries, joins, includes): return queries.map { "(\($0.description))" }.joined(separator: " || ") + " Joins: \(joins.map { $0.name }.joined(separator: ","))" + " Includes: \(includes.map { $0.name }.joined(separator: ","))"
        }
    }
    
}
