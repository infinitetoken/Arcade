//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

enum StorableError: Error {
    case noAdapter
}

public protocol Storable: Codable {
    
    static var table: Table { get }
    static var adapter: Adapter? { get }
    
    var uuid: UUID { get set }
    
    var dictionary: [String: Any] { get }

}

public extension Storable {
    
    public static var adapter: Adapter? {
        return nil
    }
    
    public var table: Table { return Self.table }
    public var adapter: Adapter? { return Self.adapter }
    
}

public extension Storable {
    
    public static func all() -> Future<[Self]> {
        guard let adapter = self.adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.fetch()
    }
    
    public static func fetch(query: Query?) -> Future<[Self]> {
        guard let adapter = self.adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.fetch(query: query)
    }
    
    public static func fetch(query: Query?, sorts: [Sort], limit: Int, offset: Int) -> Future<[Self]> {
        guard let adapter = self.adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.fetch(query: query, sorts: sorts, limit: limit, offset: offset)
    }
    
    public static func find(uuid: UUID) -> Future<Self?> {
        guard let adapter = self.adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.find(uuid: uuid)
    }
    
    public static func find(uuids: [UUID]) -> Future<[Self]> {
        guard let adapter = self.adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.find(uuids: uuids)
    }
    
    public func save() -> Future<Bool> {
        guard let adapter = self.adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.find(uuid: self.uuid).then { (result: Self?) -> Future<Bool> in
            if let result = result {
                return adapter.update(storable: result)
            } else {
                return adapter.insert(storable: self)
            }
        }
    }
    
    public func delete() -> Future<Bool> {
        guard let adapter = self.adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.delete(uuid: self.uuid, type: Self.self)
    }
    
}
