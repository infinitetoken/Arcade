//
//  InMemoryAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public class InMemoryAdapter {
    
    private var store: [String : AdapterTable?] = [:]
    
    public init() {}
    
}

public extension InMemoryAdapter {
    
    private class AdapterTable {
        var storables: [Storable] = []
        
        func insert(_ storable: Storable) -> Bool {
            self.storables.append(storable)
            return true
        }
        
        func find(_ uuid: UUID) -> Storable? {
            return self.storables.filter { return $0.uuid == uuid }.first
        }
        
        func fetch(_ query: Query?) -> [Storable] {
            guard let query = query else { return self.storables }
            
            return self.storables.filter { return $0.query(query: query) }
        }
        
        func update(_ storable: Storable) -> Bool {
            guard let existingStorable = self.find(storable.uuid) else { return false }
            
            return (self.delete(existingStorable) && self.insert(storable))
        }
        
        func delete(_ storable: Storable) -> Bool {
            guard let storable = self.find(storable.uuid) else { return false }
            
            self.storables = self.storables.filter { return $0.uuid != storable.uuid }
            return true
        }
        
        func count(query: Query?) -> Int {
            return self.fetch(query).count
        }
    }
    
}

extension InMemoryAdapter: Adapter {
    
    public func connect() -> Future<Bool> {
        return Future(true)
    }
    
    public func disconnect() -> Future<Bool> {
        return Future(true)
    }
    
    public func insert<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { operation in
            guard let adapterTable = self.store[table.name] as? AdapterTable else {
                let adapterTable = AdapterTable()
                self.store[table.name] = adapterTable
                operation(.success(adapterTable.insert(storable)))
                return
            }
            
            operation(.success(adapterTable.insert(storable)))
        }
    }
    
    public func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I : Storable, T : Table {
        guard let adapterTable = self.store[table.name] as? AdapterTable else { return Future(nil) }
        
        return Future(adapterTable.find(uuid) as? I)
    }
    
    public func fetch<I, T>(table: T, query: Query?) -> Future<[I]> where I : Storable, T : Table {
        guard let adapterTable = self.store[table.name] as? AdapterTable else { return Future([]) }
        
        return Future(adapterTable.fetch(query) as! [I])
    }
    
    public func update<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        guard let adapterTable = self.store[table.name] as? AdapterTable else { return Future(false) }
        
        return Future(adapterTable.update(storable))
    }
    
    public func delete<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        guard let adapterTable = self.store[table.name] as? AdapterTable else { return Future(false) }
        
        return Future(adapterTable.delete(storable))
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        guard let adapterTable = self.store[table.name] as? AdapterTable else { return Future(0) }
        
        return Future(adapterTable.count(query: query))
    }
    
}
