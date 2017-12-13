//
//  InMemoryAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public enum InMemoryAdapterError: Error {
    case insertFailed
    case updateFailed
    case deleteFailed
    case noResult
    case error(error: Error)
}

public final class InMemoryAdapter {
    
    private var store: [String : AdapterTable] = [:]
    
    public init() {}
    
    private init(_ store: [String : AdapterTable]) {
        self.store = store
    }
    
}

public extension InMemoryAdapter {
    
    private struct AdapterTable {
        
        var storables: [Storable] = []
        
        mutating func insert(_ storable: Storable) -> Bool {
            self.storables.append(storable)
            return true
        }
        mutating func insert(_ storables: [Storable]) -> Bool {
            self.storables.append(contentsOf: storables)
            return true
        }
        
        func find(_ uuid: UUID) -> Storable? { return self.storables.filter { $0.uuid == uuid }.first }
        func find(_ uuids: [UUID]) -> [Storable] { return self.storables.filter { uuids.contains($0.uuid) } }
        
        func fetch(_ query: Query?) -> [Storable] {
            guard let query = query else { return self.storables }
            return self.storables.filter { $0.query(query: query) }
        }
        
        mutating func update(_ storable: Storable) -> Bool {
            guard let existingStorable = self.find(storable.uuid) else { return false }
            return (self.delete(existingStorable.uuid) && self.insert(storable))
        }
        mutating func update(_ storables: [Storable]) -> Bool {
            let found = self.storables.filter{ storables.map{ $0.uuid }.contains($0.uuid) }
            guard found.count >= storables.count else { return false }
            return (delete(storables.map{ $0.uuid }) && insert(storables))
        }
        
        mutating func delete(_ uuid: UUID) -> Bool {
            self.storables = self.storables.filter { $0.uuid != uuid }
            return true
        }
        mutating func delete(_ uuids: [UUID]) -> Bool {
            self.storables = self.storables.filter { !(uuids.contains($0.uuid)) }
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
        var adapterTable = self.store[table.name] ?? AdapterTable()
        guard adapterTable.insert(storable) else { return Future(InMemoryAdapterError.insertFailed) }
        self.store[table.name] = adapterTable
        return Future(true)
    }
    public func insert<I, T>(table: T, storables: [I]) -> Future<Bool> where I : Storable, T : Table {
        var adapterTable = self.store[table.name] ?? AdapterTable()
        guard adapterTable.insert(storables) else { return Future(InMemoryAdapterError.insertFailed) }
        self.store[table.name] = adapterTable
        return Future(true)
    }
    
    public func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I : Storable, T : Table {
        guard let adapterTable = self.store[table.name] else { return Future(nil) }
        return Future(adapterTable.find(uuid) as? I)
    }
    public func find<I, T>(table: T, uuids: [UUID]) -> Future<[I]> where I : Storable, T : Table {
        guard let adapterTable = self.store[table.name] else { return Future([]) }
        return Future(adapterTable.find(uuids) as? [I] ?? [])
    }
    
    public func fetch<I, T>(table: T, query: Query?) -> Future<[I]> where I : Storable, T : Table {
        guard let adapterTable = self.store[table.name] else { return Future([]) }
        return Future(adapterTable.fetch(query) as! [I])
    }
    
    public func update<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        guard var adapterTable = self.store[table.name], adapterTable.update(storable)
            else { return Future(InMemoryAdapterError.updateFailed) }
        self.store[table.name] = adapterTable
        return Future(true)
    }
    public func update<I, T>(table: T, storables: [I]) -> Future<Bool> where I : Storable, T : Table {
        guard var adapterTable = self.store[table.name], adapterTable.update(storables)
            else { return Future(InMemoryAdapterError.updateFailed) }
        self.store[table.name] = adapterTable
        return Future(true)
    }
    
    public func delete<I, T>(table: T, uuid: UUID, type: I.Type) -> Future<Bool> where I : Storable, T : Table {
        guard var adapterTable = self.store[table.name], adapterTable.delete(uuid)
            else { return Future(InMemoryAdapterError.deleteFailed) }
        self.store[table.name] = adapterTable
        return Future(true)
    }
    public func delete<I, T>(table: T, uuids: [UUID], type: I.Type) -> Future<Bool> where I : Storable, T : Table {
        guard var adapterTable = self.store[table.name], adapterTable.delete(uuids)
            else { return Future(InMemoryAdapterError.deleteFailed) }
        self.store[table.name] = adapterTable
        return Future(true)
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        guard let adapterTable = self.store[table.name] else { return Future(0) }
        return Future(adapterTable.count(query: query))
    }
    
}

