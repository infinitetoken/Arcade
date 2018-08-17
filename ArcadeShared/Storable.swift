//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import Future

public func !=(lhs: Storable, rhs: Storable) -> Bool { return lhs.uuid != rhs.uuid }
public func ==(lhs: Storable, rhs: Storable) -> Bool { return lhs.uuid == rhs.uuid }

public protocol Storable: Codable {
    
    static var table: Table { get }
    
    var uuid: String { get set }

}

public extension Storable {
    
    public var table: Table { return Self.table }
    
}

public extension Storable {
    
    public static func all(adapter: Adapter) -> Future<[Self]> {
        return adapter.fetch()
    }
    
    public static func all(sorts: [Sort], limit: Int, offset: Int, adapter: Adapter) -> Future<[Self]> {
        return adapter.fetch(query: nil, sorts: sorts, limit: limit, offset: offset)
    }
    
    public static func fetch(query: Query?, adapter: Adapter) -> Future<[Self]> {
        return adapter.fetch(query: query)
    }
    
    public static func fetch(query: Query?, sorts: [Sort], limit: Int, offset: Int, adapter: Adapter) -> Future<[Self]> {
        return adapter.fetch(query: query, sorts: sorts, limit: limit, offset: offset)
    }
    
    public static func find(uuid: String, adapter: Adapter) -> Future<Self?> {
        return adapter.find(uuid: uuid)
    }
    
    public static func find(uuids: [String], sorts: [Sort], limit: Int, offset: Int, adapter: Adapter) -> Future<[Self]> {
        return adapter.find(uuids: uuids, sorts: sorts, limit: limit, offset: offset)
    }
    
    public func save(adapter: Adapter) -> Future<Bool> {
        return adapter.find(uuid: self.uuid).then { (result: Self?) -> Future<Bool> in
            if let result = result {
                return adapter.update(storable: result)
            } else {
                return adapter.insert(storable: self)
            }
        }
    }
    
    public func delete(adapter: Adapter) -> Future<Bool> {
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
