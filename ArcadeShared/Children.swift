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
    public let foreignKey: String
    
    
    public init(uuid: UUID?, foreignKey: String) {
        if let uuid = uuid { self.uuids = [uuid] } else { self.uuids = [] }
        self.foreignKey = foreignKey
        self.parents = nil
        self.parent = nil
    }
    
    public init(uuids: [UUID], foreignKey: String) {
        self.uuids = uuids
        self.foreignKey = foreignKey
        self.parents = nil
        self.parent = nil
    }
    
    init(parents: Future<[P]>, foreignKey: String) {
        self.uuids = []
        self.foreignKey = foreignKey
        self.parents = parents
        self.parent = nil
    }
    
    init(parent: Future<P?>, foreignKey: String) {
        self.uuids = []
        self.foreignKey = foreignKey
        self.parents = nil
        self.parent = parent
    }
    

    public func all() -> Future<[C]> {
        guard let adapter = P.adapter else { return Future(ChildrenError.noAdapter) }
        
        if let parents = parents {
            return parents.then({ (parents) -> Future<[C]> in
                return adapter.fetch(query: Query.or(parents.map { Expression.equal(self.foreignKey, $0.uuid) }))
            })
        } else if let parent = parent {
            return parent.then({ (parent) -> Future<[C]> in
                guard let parent = parent else { return Future([]) }
                return adapter.fetch(query: Query.expression(.equal(self.foreignKey, parent.uuid)))
            })
        } else {
            guard uuids.count > 0 else { return Future(ChildrenError.noUUID) }
            return adapter.fetch(query: Query.or(uuids.map { Expression.equal(foreignKey, $0) }))
        }
    }

    public func fetch(query: Query?) -> Future<[C]> {
        guard let adapter = P.adapter else { return Future(ChildrenError.noAdapter) }
        
        if let parents = parents {
            return parents.then({ (parents) -> Future<[C]> in
                let uuids = Query.or(parents.map { Expression.equal(self.foreignKey, $0.uuid) })
                
                if let query = query {
                    return adapter.fetch(query: Query.compoundAnd([query, uuids]))
                } else {
                    return adapter.fetch(query: uuids)
                }
            })
        } else if let parent = parent {
            return parent.then({ (parent) -> Future<[C]> in
                guard let parent = parent else { return Future([]) }
                let uuid = Query.expression(.equal(self.foreignKey, parent.uuid))
                
                if let query = query {
                    return adapter.fetch(query: Query.compoundAnd([query, uuid]))
                } else {
                    return adapter.fetch(query: uuid)
                }
            })
        } else {
            guard uuids.count > 0 else { return Future(ChildrenError.noUUID) }
            
            let expressions = uuids.map { Expression.equal(foreignKey, $0) }
            
            if let query = query {
                return adapter.fetch(query: Query.compoundAnd([query, Query.or(expressions)]))
            } else {
                return adapter.fetch(query: Query.or(expressions))
            }
        }
    }

    public func find(uuid: UUID) -> Future<C?> {
        guard let adapter = P.adapter else { return Future(ChildrenError.noAdapter) }
        
        let expressions = uuids.map { Expression.equal(foreignKey, $0) }
        let query = Query.compoundAnd([Query.or(expressions), Query.expression(.equal("uuid", uuid))])
        
        return adapter.fetch(query: query).transform({ (storables: [C]) -> C? in
            storables.first
        })
    }
    
}


public extension Children {
    
    public func parents<T>(toParent: @escaping (C) -> UUID) -> Parents<C, T> {
        return Parents<C, T>(all(), toParent: toParent)
    }
    
    public func parents<T>(afterFetch query: Query?, toParent: @escaping (C) -> UUID) -> Parents<C, T> {
        return Parents<C, T>(fetch(query: query), toParent: toParent)
    }
    
    
    public func children<T>(_ foreignKey: String) -> Children<C, T> {
        return Children<C, T>(parents: all(), foreignKey: foreignKey)
    }
    
    public func children<T>(afterFetch query: Query?, foreignKey: String) -> Children<C, T> {
        return Children<C, T>(parents: fetch(query: query), foreignKey: foreignKey)
    }
    
}
