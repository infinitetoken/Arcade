//
//  Siblings.swift
//  Arcade
//
//  Created by Paul Foster on 1/30/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation


public struct Siblings<Origin, Destination, Through> where Origin: Storable, Destination: Storable, Through: Storable {
    
    internal let origin: Origin
    
    
    public init(_ origin: Origin) {
        self.origin = origin
    }
    
    
    public func all() -> Future<[Destination]> {
        let query = Query.expression(.equal(origin.table.name, origin.uuid))
        let future: Future<[Through]> = Through.adapter.fetch(query: query)
        
        return future.then { (storables) -> Future<[Destination]> in
            return Destination.adapter.find(uuids: storables.flatMap { $0.parents[Destination.table.name] })
        }
    }
    
    public func query(_ expression: Expression) -> Future<[Destination]> {
        let query = Query.expression(.equal(origin.table.name, origin.uuid))
        let future: Future<[Through]> = Through.adapter.fetch(query: query)
        
        return future.then { (storables) -> Future<[Destination]> in
            let findExpression = Expression.inside("uuid", storables.flatMap { $0.parents[Destination.table.name] })
            let query = Query.and([expression, findExpression])
            
            return Destination.adapter.fetch(query: query)
        }
    }
    
    public func query(and expressions: [Expression]) -> Future<[Destination]> {
        let query = Query.expression(.equal(origin.table.name, origin.uuid))
        let future: Future<[Through]> = Through.adapter.fetch(query: query)
        
        return future.then { (storables) -> Future<[Destination]> in
            let findExpression = Expression.inside("uuid", storables.flatMap { $0.parents[Destination.table.name] })
            let query = Query.and([findExpression]+expressions)
            
            return Destination.adapter.fetch(query: query)
        }
    }
    
    
}
