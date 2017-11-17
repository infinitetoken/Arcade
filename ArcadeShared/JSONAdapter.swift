//
//  JSONAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/17/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public class JSONAdapter {
    
    private var store: [String : Any] = [:]
    
    public init() {}
    
}


private protocol AnyAdapterTable {
    func count(query: Query?) -> Int
}


public extension JSONAdapter {
    
    private struct AdapterTable<T: Storable>: Codable, AnyAdapterTable {
        
        var storables: [T] = []
        
        mutating func insert(_ storable: T) -> Bool {
            self.storables.append(storable)
            return true
        }
        
        func find(_ uuid: UUID) -> T? {
            return self.storables.filter { $0.uuid == uuid }.first
        }
        
        func fetch(_ query: Query?) -> [T] {
            guard let query = query else { return self.storables }
            return self.storables.filter { $0.query(query: query) }
        }
        
        mutating func update(_ storable: T) -> Bool {
            guard let existingStorable = self.find(storable.uuid) else { return false }
            return (self.delete(existingStorable) && self.insert(storable))
        }
        
        mutating func delete(_ storable: T) -> Bool {
            guard let storable = self.find(storable.uuid) else { return false }
            
            self.storables = self.storables.filter { $0.uuid != storable.uuid }
            return true
        }
        
        func count(query: Query?) -> Int {
            return self.fetch(query).count
        }
    }
    
}

extension JSONAdapter: Adapter {
    
    public func connect() -> Future<Bool> {
        return Future(true)
    }
    
    public func disconnect() -> Future<Bool> {
        return Future(true)
    }
    
    public func insert<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { operation in
            guard var adapterTable = self.store[table.name] as? AdapterTable<I> else {
                var adapterTable = AdapterTable<I>()
                let result = adapterTable.insert(storable)
                self.store[table.name] = adapterTable
                operation(.success(result))
                return
            }
            
            let result = adapterTable.insert(storable)
            self.store[table.name] = adapterTable
            
            operation(.success(result))
        }
    }
    
    public func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I : Storable, T : Table {
        guard let adapterTable = self.store[table.name] as? AdapterTable<I> else { return Future(nil) }
        return Future(adapterTable.find(uuid))
    }
    
    public func fetch<I, T>(table: T, query: Query?) -> Future<[I]> where I : Storable, T : Table {
        guard let adapterTable = self.store[table.name] as? AdapterTable<I> else { return Future([]) }
        return Future(adapterTable.fetch(query))
    }
    
    public func update<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        guard var adapterTable = self.store[table.name] as? AdapterTable<I> else { return Future(false) }
        let result = adapterTable.update(storable)
        self.store[table.name] = adapterTable
        
        return Future(result)
    }
    
    public func delete<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        guard var adapterTable = self.store[table.name] as? AdapterTable<I> else { return Future(false) }
        let result = adapterTable.delete(storable)
        self.store[table.name] = adapterTable
        
        return Future(result)
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        guard let adapterTable = self.store[table.name] as? AnyAdapterTable else { return Future(0) }
        return Future(adapterTable.count(query: query))
    }
    
}
