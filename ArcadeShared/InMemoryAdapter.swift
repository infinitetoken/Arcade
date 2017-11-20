//
//  InMemoryAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct InMemoryAdapter {
    
    private var store: [String : AnyAdapterTable] = [:]
    
    
    public init() {}
    
    private init(_ store: [String : AnyAdapterTable]) {
        self.store = store
    }
    
}


public extension InMemoryAdapter {
    public func encode<U: Storable>(table: Table) -> EncodeResult<U> {
        guard let adapterTable = self.store[table.name] as? AdapterTable<U> else { return EncodeResult(data: nil) }
        
        let encoder = JSONEncoder()
        
        var data: Data?
        
        do {
            data = try encoder.encode(adapterTable)
        } catch {
            print(error)
        }
        
        return EncodeResult(data: data)
    }
}


public extension InMemoryAdapter {
    
    private struct AdapterTable<T: Storable>: AnyAdapterTable {
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

extension InMemoryAdapter: Adapter {
    
    public func connect() -> Future<InMemoryAdapter> {
        return Future(self)
    }
    
    public func disconnect() -> Future<Bool> {
        return Future(true)
    }
    
    public func insert<I, T>(table: T, storable: I) -> Future<InMemoryAdapter> where I : Storable, T : Table {
        var store = self.store
        var success = false
        
        if var adapterTable = self.store[table.name] as? AdapterTable<I> {
            success = adapterTable.insert(storable)
            store[table.name] = adapterTable
        } else {
            var adapterTable = AdapterTable<I>()
            success = adapterTable.insert(storable)
            store[table.name] = adapterTable
        }
        
        if success {
            return Future<InMemoryAdapter> { $0(.success(InMemoryAdapter(store))) }
        } else {
            return Future(JSONAdapterError.insertFailed)
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
    
    public func update<I, T>(table: T, storable: I) -> Future<InMemoryAdapter> where I : Storable, T : Table {
        guard var adapterTable = self.store[table.name] as? AdapterTable<I> else { return Future(JSONAdapterError.updateFailed) }
        let success = adapterTable.update(storable)
        var store = self.store
        
        store[table.name] = adapterTable
        
        if success {
            return Future(InMemoryAdapter(store))
        } else {
            return Future(JSONAdapterError.updateFailed)
        }
    }
    
    public func delete<I, T>(table: T, storable: I) -> Future<InMemoryAdapter> where I : Storable, T : Table {
        guard var adapterTable = self.store[table.name] as? AdapterTable<I> else { return Future(JSONAdapterError.deleteFailed) }
        let success = adapterTable.delete(storable)
        var store = self.store
        
        store[table.name] = adapterTable
        
        if success {
            return Future(InMemoryAdapter(store))
        } else {
            return Future(JSONAdapterError.deleteFailed)
        }
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        guard let adapterTable = self.store[table.name] else { return Future(0) }
        return Future(adapterTable.count(query: query))
    }
    
}
