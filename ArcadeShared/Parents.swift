//
//  Parents.swift
//  Arcade
//
//  Created by Paul Foster on 2/10/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct Parents<C,P> where C: Storable, P: Storable {
    
    let uuids: [String]
    
    let children: Future<[C]>?
    let toParent: ((C) -> String?)?
    
    public init(_ uuids: [String]) {
        self.uuids = uuids
        self.children = nil
        self.toParent = nil
    }
    
    init(_ children: Future<[C]>, toParent: @escaping (C) -> String?) {
        self.uuids = []
        self.children = children
        self.toParent = toParent
    }
    
    public func all(sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter? = C.adapter) -> Future<[P]> {
        guard let adapter = adapter else { return Future(ParentError.noAdapter) }
        guard let toParent = self.toParent,
            let children = self.children
            else { return adapter.find(uuids: uuids, sorts: sorts, limit: limit, offset: offset) }

        return children.then({ (children) -> Future<[P]> in
            return adapter.find(uuids: children.compactMap(toParent), sorts: sorts, limit: limit, offset: offset)
        })
    }
    
    public func fetch(query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter? = C.adapter) -> Future<[P]> {
        guard let adapter = adapter else { return Future(ParentError.noAdapter) }
        guard let toParent = self.toParent,
            let children = self.children
            else {
                if let query = query {
                    return adapter.fetch(query: Query.compoundAnd([query, Query.or(uuids.map { .equal("uuid", $0) })]), sorts: sorts, limit: limit, offset: offset)
                } else {
                    return adapter.fetch(query: Query.or(uuids.map { .equal("uuid", $0) }), sorts: sorts, limit: limit, offset: offset)
                }
        }
        
        return children.then { (children) -> Future<[P]> in
            if let query = query {
                return adapter.fetch(query: Query.compoundAnd([query, Query.or(children.map { .equal("uuid", toParent($0)) })]), sorts: sorts, limit: limit, offset: offset)
            } else {
                return adapter.fetch(query: Query.or(children.compactMap{ toParent($0) }.map { .equal("uuid", $0) }), sorts: sorts, limit: limit, offset: offset)
            }
        }
    }
    
}

public extension Parents {
    
    public func parents<T>(toParent: @escaping (P) -> String?) -> Parents<P, T> {
        return Parents<P, T>(all(), toParent: toParent)
    }
    
    public func parents<T>(afterFetch query: Query?, toParent: @escaping (P) -> String?) -> Parents<P, T> {
        return Parents<P, T>(fetch(query: query), toParent: toParent)
    }
    
    public func children<T>(afterFetch query: Query?) -> Children<P, T> {
        return Children<P, T>(parents: fetch(query: query))
    }
    
}
