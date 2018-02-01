//
//  Parent.swift
//  Arcade
//
//  Created by Paul Foster on 1/30/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

enum ParentError: Error {
    case noUUID
    case noAdapter
}

public struct Parent<Child, Parent> where Child: Storable, Parent: Storable {
    
    public let uuid: UUID?
    
    public init(uuid: UUID?) {
        self.uuid = uuid
    }
    
    public func find() -> Future<Parent?> {
        guard let uuid = self.uuid else { return Future(ParentError.noUUID) }
        guard let adapter = Child.adapter else { return Future(ParentError.noAdapter) }
        
        return adapter.find(uuid: uuid)
    }
    
}
