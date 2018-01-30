//
//  Parent.swift
//  Arcade
//
//  Created by Paul Foster on 1/30/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation


public struct Parent<Child, Parent> where Parent: Storable, Child: Storable  {
    
    internal let child: Child
    
    
    public init(_ child: Child) {
        self.child = child
    }
    
    
    public func storable() -> Future<Parent?> {
        guard let uuid = child.parents[Parent.table.name] else { return Future(StorableError.noParentUUID) }
        return Parent.adapter.find(uuid: uuid)
    }
    
}
