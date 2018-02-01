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

public struct Parent<C, P> where C: Storable, P: Storable {

    public let uuid: UUID?

    public init(_ uuid: UUID?) {
        self.uuid = uuid
    }
    
    public init(_ child: C?) {
        self.uuid = child?.uuid
    }
    
    
    public func find() -> Future<P?> {
        guard let uuid = self.uuid else { return Future(ParentError.noUUID) }
        guard let adapter = C.adapter else { return Future(ParentError.noAdapter) }

        return adapter.find(uuid: uuid)
    }

}
