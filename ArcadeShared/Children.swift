//
//  Children.swift
//  Arcade
//
//  Created by Paul Foster on 1/30/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

enum ChildrenError: Error {
    case noUUID
    case noAdapter
    case noForeignKey
}

public struct Children<Parent, Child> where Parent: Storable, Child: Storable {
    
    public let uuid: UUID?
    
    public init(uuid: UUID?) {
        self.uuid = uuid
    }

    public func all() -> Future<[Child]> {
        guard let uuid = self.uuid else { return Future(ChildrenError.noUUID) }
        guard let adapter = Parent.adapter else { return Future(ChildrenError.noAdapter) }

        let query = Query.expression(.equal(Parent.foreignKey, uuid))
        
        return adapter.fetch(query: query)
    }
    
    public func fetch(query: Query?) -> Future<[Child]> {
        guard let uuid = self.uuid else { return Future(ChildrenError.noUUID) }
        guard let adapter = Parent.adapter else { return Future(ChildrenError.noAdapter) }
        
        if let query = query {
            return adapter.fetch(query: Query.compoundAnd([Query.expression(.equal(Parent.foreignKey, uuid)), query]))
        } else {
            return adapter.fetch(query: Query.expression(.equal(Parent.foreignKey, uuid)))
        }
    }

    public func find(uuid: UUID) -> Future<Child?> {
        guard let adapter = Parent.adapter else { return Future(ChildrenError.noAdapter) }
        
        return adapter.find(uuid: uuid)
    }
    
}
