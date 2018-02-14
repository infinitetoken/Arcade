//
//  Parent.swift
//  Arcade
//
//  Created by Paul Foster on 1/30/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

enum ParentError: Error {
    case noAdapter
    case noUUID
}

public struct Parent<C, P> where C: Storable, P: Storable {

    public let uuid: UUID?
    
    let child: Future<C?>?
    let toParent: ((C) -> UUID?)?

    
    public init(uuid: UUID?) {
        self.uuid = uuid
        self.child = nil
        self.toParent = nil
    }
    
    init(child: Future<C?>, toParent: @escaping (C) -> UUID?) {
        self.uuid = nil
        self.child = child
        self.toParent = toParent
    }
    
    
    public func find() -> Future<P?> {
        guard let adapter = C.adapter else { return Future(ParentError.noAdapter) }
        
        if let toParent = toParent {
            if let child = child {
                return child.then({ (child) -> Future<P?> in
                    guard let child = child,
                    let uuid = toParent(child)
                        else { return Future(nil) }
                    return adapter.find(uuid: uuid)
                })
            }
        }
        
        guard let uuid = self.uuid else { return Future(ParentError.noUUID) }
        return adapter.find(uuid: uuid)
    }
    
}

public extension Parent {
    
    public func parent<T>(toParent: @escaping (P) -> UUID?) -> Parent<P, T> {
        return Parent<P, T>(child: find(), toParent: toParent)
    }
    
    public func children<T>(_ foreignKey: String) -> Children<P, T> {
        return Children<P, T>(parent: find(), foreignKey: foreignKey)
    }
    
}
