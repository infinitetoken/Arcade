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

    public let uuid: String?
    
    public init(uuid: String?) {
        self.uuid = uuid
    }
    
    public func all(sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter? = Origin.adapter) -> Future<[Destination]> {
        guard let uuid = self.uuid else { return Future(SiblingsError.noUUID) }
        guard let adapter = adapter else { return Future(SiblingsError.noAdapter) }

        return adapter.fetch(query: Query.expression(.equal(Origin.table.foreignKey, uuid))).transform({ (throughs: [Through]) -> [String] in
            return throughs.compactMap { return $0.dictionary[Destination.table.foreignKey] as? String }
        }).then { (throughs: [String]) -> Future<[Destination]> in
            return adapter.find(uuids: throughs, sorts: sorts, limit: limit, offset: offset)
        }
    }

    public func fetch(query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, adapter: Adapter? = Origin.adapter) -> Future<[Destination]> {
        guard let uuid = self.uuid else { return Future(SiblingsError.noUUID) }
        guard let adapter = adapter else { return Future(SiblingsError.noAdapter) }

        return adapter.fetch(query: Query.expression(.equal(Origin.table.foreignKey, uuid))).transform({ (throughs: [Through]) -> [String] in
            return throughs.compactMap { return $0.dictionary[Destination.table.foreignKey] as? String }
        }).then { (throughs: [String]) -> Future<[Destination]> in
            if let query = query {
                return adapter.fetch(query: Query.compoundAnd([Query.expression(.inside("uuid", throughs)), query]), sorts: sorts, limit: limit, offset: offset)
            } else {
                return adapter.find(uuids: throughs, sorts: sorts, limit: limit, offset: offset)
            }
        }
    }
    
    public func find(uuid: String, adapter: Adapter? = Destination.adapter) -> Future<Destination?> {
        guard let adapter = adapter else { return Future(SiblingsError.noAdapter) }
        
        return adapter.find(uuid: uuid)
    }

}
