//
//  Parents.swift
//  Arcade
//
//  Created by Paul Foster on 2/10/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct Parents<C,P> where C: Storable, P: Storable {
    
    let uuids: [UUID]
    
    let children: Future<[C]>?
    let toParent: ((C) -> UUID)?
    
    
    public init(_ uuids: [UUID]) {
        self.uuids = uuids
        self.children = nil
        self.toParent = nil
    }
    
    init(_ children: Future<[C]>, toParent: @escaping (C) -> UUID) {
        self.uuids = []
        self.children = children
        self.toParent = toParent
    }
    
    
    public func all() -> Future<[P]> {
        guard let adapter = C.adapter else { return Future(ParentError.noAdapter) }
        guard let toParent = self.toParent,
            let children = self.children
            else { return adapter.find(uuids: uuids) }

        return children.then({ (children) -> Future<[P]> in
            return adapter.find(uuids: children.map(toParent))
        })
    }
    
    
    public func fetch(query: Query?) -> Future<[P]> {
        guard let adapter = C.adapter else { return Future(ParentError.noAdapter) }
        guard let toParent = self.toParent,
            let children = self.children
            else {
                if let query = query {
                    return adapter.fetch(query: Query.compoundAnd([query, Query.or(uuids.map { .equal("uuid", $0) })]))
                } else {
                    return adapter.fetch(query: Query.or(uuids.map { .equal("uuid", $0) }))
                }
        }
        
        return children.then { (children) -> Future<[P]> in
            if let query = query {
                return adapter.fetch(query: Query.compoundAnd([query, Query.or(children.map { .equal("uuid", toParent($0)) })]))
            } else {
                return adapter.fetch(query: Query.or(children.map { .equal("uuid", toParent($0)) }))
            }
        }
    }
    
}


extension Parents {
    
    func parents<T>(toParent: @escaping (P) -> UUID) -> Parents<P, T> {
        return Parents<P, T>(all(), toParent: toParent)
    }
    
    func parents<T>(afterFetch query: Query?, toParent: @escaping (P) -> UUID) -> Parents<P, T> {
        return Parents<P, T>(fetch(query: query), toParent: toParent)
    }
    
    
    public func children<T>(_ foreignKey: String) -> Children<P, T> {
        return Children<P, T>(parents: all(), foreignKey: foreignKey)
    }
    
    public func children<T>(afterFetch query: Query?, foreignKey: String) -> Children<P, T> {
        return Children<P, T>(parents: fetch(query: query), foreignKey: foreignKey)
    }
    
}
