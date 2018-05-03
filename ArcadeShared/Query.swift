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


extension Query: Encodable {
    
    enum CodingKeys: CodingKey {
        case query
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.description, forKey: .query)
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
