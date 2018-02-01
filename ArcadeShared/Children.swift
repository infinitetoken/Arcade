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

public struct Children<P, C> where P: Storable, C: Storable {
    
    public let uuid: UUID?
    
    public init(_ uuid: UUID?) {
        self.uuid = uuid
    }
    
    public init(_ parent: P?) {
        self.uuid = parent?.uuid
    }

    public func all() -> Future<[C]> {
        guard let uuid = self.uuid else { return Future(ChildrenError.noUUID) }
        guard let adapter = P.adapter else { return Future(ChildrenError.noAdapter) }

        let query = Query.expression(.equal(P.foreignKey, uuid))
        
        return adapter.fetch(query: query)
    }
    
    public func query(_ query: Query) -> Future<[C]> {
        guard let uuid = self.uuid else { return Future(ChildrenError.noUUID) }
        guard let adapter = P.adapter else { return Future(ChildrenError.noAdapter) }
        
        let compoundQuery = Query.compoundAnd([Query.expression(.equal(P.foreignKey, uuid)), query])
        
        return adapter.fetch(query: compoundQuery)
    }

    public func find(_ uuid: UUID) -> Future<C?> {
        guard let adapter = P.adapter else { return Future(ChildrenError.noAdapter) }
        
        return adapter.find(uuid: uuid)
    }
    
}
