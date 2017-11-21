//
//  JSONAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/17/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public enum JSONAdapterError: Error {
    case insertFailed
    case updateFailed
    case deleteFailed
    case saveFailed
    case tableNotFound
    case encodeFailed(error: Error)
    case decodeFailed(error: Error)
    case noURL
    case noResult
    case error(error: Error)
}

public struct JSONAdapter {
    
    private var store: [String : AdapterTable] = [:]
    private var directory: URL?
    
    public init(directory: URL) {
        self.directory = directory
    }
    
    private init(_ store: [String : AdapterTable], directory: URL?) {
        self.store = store
        self.directory = directory
    }
    
}

public extension JSONAdapter {
    
    private struct AdapterTable {
        
        var storables: [Storable] = []
        
        mutating func insert(_ storable: Storable) -> Bool {
            self.storables.append(storable)
            return true
        }
        
        func find(_ uuid: UUID) -> Storable? {
            return self.storables.filter { $0.uuid == uuid }.first
        }
        
        func fetch(_ query: Query?) -> [Storable] {
            guard let query = query else { return self.storables }
            return self.storables.filter { $0.query(query: query) }
        }
        
        mutating func update(_ storable: Storable) -> Bool {
            guard let existingStorable = self.find(storable.uuid) else { return false }
            return (self.delete(existingStorable.uuid) && self.insert(storable))
        }
        
        mutating func delete(_ uuid: UUID) -> Bool {
            self.storables = self.storables.filter { $0.uuid != uuid }
            return true
        }
        
        func count(query: Query?) -> Int {
            return self.fetch(query).count
        }
        
    }
    
}

extension JSONAdapter: Adapter {
    
    public func connect() -> Future<JSONAdapter> {
        return Future(self)
    }
    
    public func disconnect() -> Future<JSONAdapter> {
        return Future(self)
    }
    
    public func insert<I, T>(table: T, storable: I) -> Future<JSONAdapter> where I : Storable, T : Table {
        var store = self.store
        let directory = self.directory
        
        var adapterTable = self.store[table.name] ?? AdapterTable()
        
        guard adapterTable.insert(storable)
            else { return Future(JSONAdapterError.insertFailed) }
        guard self.save(table: table, storables: adapterTable.storables as! [I])
            else { return Future(JSONAdapterError.saveFailed) }
        
        store[table.name] = adapterTable
        
        return Future(JSONAdapter(store, directory: directory))
    }
    
    public func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I : Storable, T : Table {
        var store = self.store
        
        if var adapterTable = self.store[table.name] {
            adapterTable.storables = self.load(table: table) as [I]
            store[table.name] = adapterTable
            return Future(adapterTable.find(uuid) as? I)
        } else {
            var adapterTable = AdapterTable()
            adapterTable.storables = self.load(table: table) as [I]
            store[table.name] = adapterTable
            return Future(adapterTable.find(uuid) as? I)
        }
    }
    
    public func fetch<I, T>(table: T, query: Query?) -> Future<[I]> where I : Storable, T : Table {
        var store = self.store
        
        if var adapterTable = self.store[table.name] {
            adapterTable.storables = self.load(table: table) as [I]
            store[table.name] = adapterTable
            return Future(adapterTable.fetch(query) as! [I])
        } else {
            var adapterTable = AdapterTable()
            adapterTable.storables = self.load(table: table) as [I]
            store[table.name] = adapterTable
            return Future(adapterTable.fetch(query) as! [I])
        }
    }
    
    public func update<I, T>(table: T, storable: I) -> Future<JSONAdapter> where I : Storable, T : Table {
        var adapterTable = AdapterTable()
        
        adapterTable.storables = self.load(table: table) as [I]
        
        guard adapterTable.update(storable)
            else { return Future(JSONAdapterError.updateFailed) }
        guard self.save(table: table, storables: adapterTable.storables as! [I])
            else { return Future(JSONAdapterError.saveFailed) }
        
        var store = self.store
        let directory = self.directory
        
        store[table.name] = adapterTable
        
        return Future(JSONAdapter(store, directory: directory))
    }
    
    public func delete<I, T>(table: T, uuid: UUID, type: I.Type) -> Future<JSONAdapter> where I : Storable, T : Table {
        var adapterTable = AdapterTable()
        
        adapterTable.storables = self.load(table: table) as [I]
        
        guard adapterTable.delete(uuid)
            else { return Future(JSONAdapterError.deleteFailed) }
        guard self.save(table: table, storables: adapterTable.storables as! [I])
            else { return Future(JSONAdapterError.saveFailed) }
        
        var store = self.store
        let directory = self.directory
        
        store[table.name] = adapterTable
        
        return Future(JSONAdapter(store, directory: directory))
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        guard let adapterTable = self.store[table.name] else { return Future(0) }
        return Future(adapterTable.count(query: query))
    }
    
    private func save<I, T>(table: T, storables: [I]) -> Bool where I : Storable, T : Table {
        guard let directory = self.directory else { return false }
        
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(storables)
            try data.write(to: directory.appendingPathComponent(table.name))
            return true
        } catch {
            return false
        }
    }
    
    private func load<I, T>(table: T) -> [I] where I : Storable, T : Table {
        guard let directory = self.directory else { return [] }
        
        let decoder = JSONDecoder()
        
        do {
            let data = try Data(contentsOf: directory.appendingPathComponent(table.name))
            let storables = try decoder.decode([I].self, from: data)
            return storables
        } catch {
            return []
        }
    }
    
}
