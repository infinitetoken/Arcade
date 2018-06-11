//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public func !=(lhs: Storable, rhs: Storable) -> Bool { return lhs.uuid != rhs.uuid }
public func ==(lhs: Storable, rhs: Storable) -> Bool { return lhs.uuid == rhs.uuid }

enum StorableError: Error {
    case noAdapter
}

public protocol Storable: Codable {
    
    static var table: Table { get }
    static var adapter: Adapter? { get }
    
    var uuid: String { get set }

}

public extension Storable {
    
    public static var adapter: Adapter? {
        return nil
    }
    
    public var table: Table { return Self.table }
    public var adapter: Adapter? { return Self.adapter }
    
}

public extension Storable {
    
    public static func all(adapter: Adapter? = Self.adapter) -> Future<[Self]> {
        guard let adapter = adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.fetch()
    }
    
    public static func fetch(query: Query?, adapter: Adapter? = Self.adapter) -> Future<[Self]> {
        guard let adapter = adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.fetch(query: query)
    }
    
    public static func fetch(query: Query?, sorts: [Sort], limit: Int, offset: Int, adapter: Adapter? = Self.adapter) -> Future<[Self]> {
        guard let adapter = adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.fetch(query: query, sorts: sorts, limit: limit, offset: offset)
    }
    
    public static func find(uuid: String, adapter: Adapter? = Self.adapter) -> Future<Self?> {
        guard let adapter = adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.find(uuid: uuid)
    }
    
    public static func find(uuids: [String], sorts: [Sort], limit: Int, offset: Int, adapter: Adapter? = Self.adapter) -> Future<[Self]> {
        guard let adapter = adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.find(uuids: uuids, sorts: sorts, limit: limit, offset: offset)
    }
    
    public func save(adapter: Adapter? = Self.adapter) -> Future<Bool> {
        guard let adapter = adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.find(uuid: self.uuid).then { (result: Self?) -> Future<Bool> in
            if let result = result {
                return adapter.update(storable: result)
            } else {
                return adapter.insert(storable: self)
            }
        }
    }
    
    public func delete(adapter: Adapter? = Self.adapter) -> Future<Bool> {
        guard let adapter = adapter else { return Future(StorableError.noAdapter) }
        
        return adapter.delete(uuid: self.uuid, type: Self.self)
    }
    
}

public extension Storable {
    
    public var dictionary: [String : Any] {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(self)
            
            guard let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else { return [:] }
            
            return result
        } catch {
            return [:]
        }
    }
    
}
