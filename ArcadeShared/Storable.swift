//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public protocol Storable: Codable {
    
    var uuid: UUID { get set }
    
}

extension Storable {
    
    public var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
    
    public func query(query: Query) -> Bool {
        return query.predicate().evaluate(with: self.dictionary)
    }
    
}
