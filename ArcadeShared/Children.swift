//
//  Children.swift
//  Arcade
//
//  Created by Paul Foster on 1/30/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import Future

public enum ChildrenError: Error {
    case noUUID
    case noAdapter
}

public struct Children<P, C> where P: Storable, C: Storable {

    let parents: Future<[P]>?
    let parent: Future<P?>?
    
    public let uuids: [String]
    
    public init(uuid: String?) {
        if let uuid = uuid { self.uuids = [uuid] } else { self.uuids = [] }
        self.parents = nil
        self.parent = nil
    }
    
    public init(uuids: [String]) {
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
    
    public func all(sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter) -> Future<[C]> {
        if let parents = parents {
            return parents.then({ (parents) -> Future<[C]> in
                return adapter.fetch(query: Query.or(parents.map { Expression.equal(P.table.foreignKey, $0.uuid) }), sorts: sorts, limit: limit, offset: offset)
            })
        } else if let parent = parent {
            return parent.then({ (parent) -> Future<[C]> in
                guard let parent = parent else { return Future([]) }
                return adapter.fetch(query: Query.expression(.equal(P.table.foreignKey, parent.uuid)), sorts: sorts, limit: limit, offset: offset)
            })
        } else {
            guard uuids.count > 0 else { return Future(ChildrenError.noUUID) }
            return adapter.fetch(query: Query.or(uuids.map { Expression.equal(P.table.foreignKey, $0) }), sorts: sorts, limit: limit, offset: offset)
        }
    }

    public func fetch(query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter) -> Future<[C]> {
        if let parents = parents {
            return parents.then({ (parents) -> Future<[C]> in
                let uuids = Query.or(parents.map { Expression.equal(P.table.foreignKey, $0.uuid) })
                
                if let query = query {
                    return adapter.fetch(query: Query.compoundAnd([query, uuids]), sorts: sorts, limit: limit, offset: offset)
                } else {
                    return adapter.fetch(query: uuids, sorts: sorts, limit: limit, offset: offset)
                }
            })
        } else if let parent = parent {
            return parent.then({ (parent) -> Future<[C]> in
                guard let parent = parent else { return Future([]) }
                let uuid = Query.expression(.equal(P.table.foreignKey, parent.uuid))
                
                if let query = query {
                    return adapter.fetch(query: Query.compoundAnd([query, uuid]), sorts: sorts, limit: limit, offset: offset)
                } else {
                    return adapter.fetch(query: uuid, sorts: sorts, limit: limit, offset: offset)
                }
            })
        } else {
            guard uuids.count > 0 else { return Future(ChildrenError.noUUID) }
            
            let expressions = uuids.map { Expression.equal(P.table.foreignKey, $0) }
            
            if let query = query {
                return adapter.fetch(query: Query.compoundAnd([query, Query.or(expressions)]), sorts: sorts, limit: limit, offset: offset)
            } else {
                return adapter.fetch(query: Query.or(expressions), sorts: sorts, limit: limit, offset: offset)
            }
        }
    }

    public func find(uuid: String, adapter: Adapter) -> Future<C?> {
        let expressions = uuids.map { Expression.equal(P.table.foreignKey, $0) }
        let query = Query.compoundAnd([Query.or(expressions), Query.expression(.equal("uuid", uuid))])
        
        return adapter.fetch(query: query).transform({ (storables: [C]) -> C? in
            storables.first
        })
    }
    
}

public extension Children {
    
    public func parents<T>(adapter: Adapter, toParent: @escaping (C) -> String?) -> Parents<C, T> {
        return Parents<C, T>(all(adapter: adapter), toParent: toParent)
    }
    
    public func parents<T>(afterFetch query: Query?, adapter: Adapter, toParent: @escaping (C) -> String?) -> Parents<C, T> {
        return Parents<C, T>(fetch(query: query, sorts: [], limit: 0, offset: 0, adapter: adapter), toParent: toParent)
    }
    
    public func children<T>(afterFetch query: Query?, adapter: Adapter) -> Children<C, T> {
        return Children<C, T>(parents: fetch(query: query, sorts: [], limit: 0, offset: 0, adapter: adapter))
    }
    
}
