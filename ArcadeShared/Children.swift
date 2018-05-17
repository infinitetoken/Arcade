//
//  Children.swift
//  Arcade
//
//  Created by Paul Foster on 1/30/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public enum ChildrenError: Error {
    case noUUID
    case noAdapter
}

public struct Children<P, C> where P: Storable, C: Storable {

    let parents: Future<[P]>?
    let parent: Future<P?>?
    
    public let uuids: [UUID]
    
    public init(uuid: UUID?) {
        if let uuid = uuid { self.uuids = [uuid] } else { self.uuids = [] }
        self.parents = nil
        self.parent = nil
    }
    
    public init(uuids: [UUID]) {
        self.uuids = uuids
        self.parents = nil
        self.parent = nil
    }
    
    init(parents: Future<[P]>) {
        self.uuids = []
        self.parents = parents
        self.parent = nil
    }
    
    init(parent: Future<P?>) {
        self.uuids = []
        self.parents = nil
        self.parent = parent
    }
    
    public func all(sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter? = P.adapter) -> Future<[C]> {
        guard let adapter = adapter else { return Future(ChildrenError.noAdapter) }
        
        if let parents = parents {
            return parents.then({ (parents) -> Future<[C]> in
                Swift.print("Foo: \(Query.or(parents.map { Expression.equal(P.table.foreignKey, $0.uuid.uuidString.lowercased()) }))")
                return adapter.fetch(query: Query.or(parents.map { Expression.equal(P.table.foreignKey, $0.uuid.uuidString.lowercased()) }), sorts: sorts, limit: limit, offset: offset)
            })
        } else if let parent = parent {
            return parent.then({ (parent) -> Future<[C]> in
                guard let parent = parent else { return Future([]) }
                Swift.print("Foo2: \(Query.expression(.equal(P.table.foreignKey, parent.uuid.uuidString.lowercased())))")
                return adapter.fetch(query: Query.expression(.equal(P.table.foreignKey, parent.uuid.uuidString.lowercased())), sorts: sorts, limit: limit, offset: offset)
            })
        } else {
            guard uuids.count > 0 else { return Future(ChildrenError.noUUID) }
            Swift.print("Foo3: \(Query.or(uuids.map { Expression.equal(P.table.foreignKey, $0.uuidString.lowercased()) }))")
            return adapter.fetch(query: Query.or(uuids.map { Expression.equal(P.table.foreignKey, $0.uuidString.lowercased()) }), sorts: sorts, limit: limit, offset: offset)
        }
    }

    public func fetch(query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter? = P.adapter) -> Future<[C]> {
        guard let adapter = adapter else { return Future(ChildrenError.noAdapter) }
        
        if let parents = parents {
            return parents.then({ (parents) -> Future<[C]> in
                let uuids = Query.or(parents.map { Expression.equal(P.table.foreignKey, $0.uuid.uuidString.lowercased()) })
                
                if let query = query {
                    return adapter.fetch(query: Query.compoundAnd([query, uuids]), sorts: sorts, limit: limit, offset: offset)
                } else {
                    return adapter.fetch(query: uuids, sorts: sorts, limit: limit, offset: offset)
                }
            })
        } else if let parent = parent {
            return parent.then({ (parent) -> Future<[C]> in
                guard let parent = parent else { return Future([]) }
                let uuid = Query.expression(.equal(P.table.foreignKey, parent.uuid.uuidString.lowercased()))
                
                if let query = query {
                    return adapter.fetch(query: Query.compoundAnd([query, uuid]), sorts: sorts, limit: limit, offset: offset)
                } else {
                    return adapter.fetch(query: uuid, sorts: sorts, limit: limit, offset: offset)
                }
            })
        } else {
            guard uuids.count > 0 else { return Future(ChildrenError.noUUID) }
            
            let expressions = uuids.map { Expression.equal(P.table.foreignKey, $0.uuidString.lowercased()) }
            
            if let query = query {
                return adapter.fetch(query: Query.compoundAnd([query, Query.or(expressions)]), sorts: sorts, limit: limit, offset: offset)
            } else {
                return adapter.fetch(query: Query.or(expressions), sorts: sorts, limit: limit, offset: offset)
            }
        }
    }

    public func find(uuid: UUID, adapter: Adapter? = P.adapter) -> Future<C?> {
        guard let adapter = adapter else { return Future(ChildrenError.noAdapter) }
        
        let expressions = uuids.map { Expression.equal(P.table.foreignKey, $0.uuidString.lowercased()) }
        let query = Query.compoundAnd([Query.or(expressions), Query.expression(.equal("uuid", uuid.uuidString.lowercased()))])
        
        return adapter.fetch(query: query).transform({ (storables: [C]) -> C? in
            storables.first
        })
    }
    
}

public extension Children {
    
    public func parents<T>(toParent: @escaping (C) -> UUID?) -> Parents<C, T> {
        return Parents<C, T>(all(), toParent: toParent)
    }
    
    public func parents<T>(afterFetch query: Query?, toParent: @escaping (C) -> UUID?) -> Parents<C, T> {
        return Parents<C, T>(fetch(query: query), toParent: toParent)
    }
    
    public func children<T>(afterFetch query: Query?) -> Children<C, T> {
        return Children<C, T>(parents: fetch(query: query))
    }
    
}
