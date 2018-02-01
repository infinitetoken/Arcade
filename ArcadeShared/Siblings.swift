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
    case noOriginForeignKey
    case noDestinationForeignKey
}

public struct Siblings<Origin, Destination, Through> where Origin: Storable, Destination: Storable, Through: Storable {
    
    public let uuid: UUID?
    
    public init(_ uuid: UUID?) {
        self.uuid = uuid
    }
    
    public init(_ origin: Origin?) {
        self.uuid = origin?.uuid
    }
    
    public func all() -> Future<[Destination]> {
        guard let uuid = self.uuid else { return Future(SiblingsError.noUUID) }
        guard let adapter = Origin.adapter else { return Future(SiblingsError.noAdapter) }
        
        return adapter.fetch(query: Query.expression(.equal(Origin.foreignKey, uuid))).transform({ (throughs: [Through]) -> [UUID] in
            return throughs.flatMap { $0.dictionary[Destination.foreignKey] as? UUID }
        }).then { (throughs: [UUID]) -> Future<[Destination]> in
            return adapter.fetch(query: Query.expression(.inside(Destination.idKey, throughs)))
        }
    }
    
    public func query(_ query: Query) -> Future<[Destination]> {
        guard let uuid = self.uuid else { return Future(SiblingsError.noUUID) }
        guard let adapter = Origin.adapter else { return Future(SiblingsError.noAdapter) }
        
        return adapter.fetch(query: Query.expression(.equal(Origin.foreignKey, uuid))).transform({ (throughs: [Through]) -> [UUID] in
            return throughs.flatMap { $0.dictionary[Destination.foreignKey] as? UUID }
        }).then { (throughs: [UUID]) -> Future<[Destination]> in
            return adapter.fetch(query: Query.compoundAnd([Query.expression(.inside(Destination.idKey, throughs)), query]))
        }
    }
    
}
