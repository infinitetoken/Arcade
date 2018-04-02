//
//  Siblings.swift
//  Arcade
//
//  Created by Paul Foster on 1/30/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

enum SiblingsError: Error {
    case noUUID
    case noAdapter
}

public struct Siblings<Origin, Destination, Through> where Origin: Storable, Destination: Storable, Through: Storable {

    public let uuid: UUID?
    public let originForeignKey: String
    public let destinationForeignKey: String
    public let destinationIDKey: String
    
    public init(uuid: UUID?, originForeignKey: String, destinationForeignKey: String, destinationIDKey: String) {
        self.uuid = uuid
        self.originForeignKey = originForeignKey
        self.destinationForeignKey = destinationForeignKey
        self.destinationIDKey = destinationIDKey
    }
    
    public func all(sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter? = Origin.adapter) -> Future<[Destination]> {
        guard let uuid = self.uuid else { return Future(SiblingsError.noUUID) }
        guard let adapter = adapter else { return Future(SiblingsError.noAdapter) }

        return adapter.fetch(query: Query.expression(.equal(self.originForeignKey, uuid))).transform({ (throughs: [Through]) -> [UUID] in
            return throughs.compactMap { $0.dictionary[self.destinationForeignKey] as? UUID }
        }).then { (throughs: [UUID]) -> Future<[Destination]> in
            return adapter.fetch(query: Query.expression(.inside(self.destinationIDKey, throughs)), sorts: sorts, limit: limit, offset: offset)
        }
    }

    public func fetch(query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter? = Origin.adapter) -> Future<[Destination]> {
        guard let uuid = self.uuid else { return Future(SiblingsError.noUUID) }
        guard let adapter = adapter else { return Future(SiblingsError.noAdapter) }

        return adapter.fetch(query: Query.expression(.equal(self.originForeignKey, uuid))).transform({ (throughs: [Through]) -> [UUID] in
            return throughs.compactMap { $0.dictionary[self.destinationForeignKey] as? UUID }
        }).then { (throughs: [UUID]) -> Future<[Destination]> in
            if let query = query {
                return adapter.fetch(query: Query.compoundAnd([Query.expression(.inside(self.destinationIDKey, throughs)), query]), sorts: sorts, limit: limit, offset: offset)
            } else {
                return adapter.fetch(query: Query.expression(.inside(self.destinationIDKey, throughs)), sorts: sorts, limit: limit, offset: offset)
            }
        }
    }
    
    public func find(uuid: UUID, adapter: Adapter? = Destination.adapter) -> Future<Destination?> {
        guard let adapter = adapter else { return Future(SiblingsError.noAdapter) }
        
        return adapter.find(uuid: uuid)
    }

}
