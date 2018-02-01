//
//  Children.swift
//  Arcade
//
//  Created by Paul Foster on 1/30/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation


public struct Children<Parent, Child> where Parent: Storable, Child: Storable {
    
    internal let parent: Parent
    internal let key: String
    
    
    public init(_ parent: Parent, key: String = Parent.table.name) {
        self.parent = parent
        self.key = key
    }
    
    public func all() -> Future<[Child]> {
        let query = Query.expression(.equal(key, parent.uuid))
        return Child.adapter.fetch(query: query)
    }
    
    public func find(_ uuid: UUID) -> Future<Child?> { return Child.adapter.find(uuid: uuid) }
    
    public func query(_ expression: Expression) -> Future<[Child]> {
        let query = Query.and([.equal(key, parent.uuid), expression])
        return Child.adapter.fetch(query: query)
    }
    
    public func query(and expressions: [Expression]) -> Future<[Child]> {
        let query = Query.and([.equal(key, parent.uuid)]+expressions)
        return Child.adapter.fetch(query: query)
    }
    
}
