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

open class InMemoryAdapter {
    
    private var store: [String : AdapterTable] = [:]
    
    private var undoStack: Stack = Stack()
    private var redoStack: Stack = Stack()
    
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
        func find(_ uuids: [UUID], sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> [Storable] {
            return Array(self.storables.filter { uuids.contains($0.uuid) }.sorted(with: sorts.map({ (sort) -> NSSortDescriptor in
                return sort.sortDescriptor()
            })).offset(by: offset).limit(to: limit))
        }
        
        func fetch(_ query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> [Storable] {
            guard let query = query else { return self.storables.offset(by: offset).limit(to: limit) }
            return Array(self.storables.filter { query.predicate().evaluate(with: $0.dictionary) }.sorted(with: sorts.map({ (sort) -> NSSortDescriptor in
                return sort.sortDescriptor()
            })).offset(by: offset).limit(to: limit))
        }
        
        mutating func update(_ storable: Storable) -> Bool {
            if let existingStorable = find(storable.uuid) {
                return delete(existingStorable.uuid) && insert(storable)
            } else {
                return insert(storable)
            }
        }
        mutating func update(_ storables: [Storable]) -> Bool {
            let results = storables.map { (storable) -> Bool in
                return update(storable)
            }
            return !results.contains(false)
        }
        
        mutating func delete(_ uuid: UUID) -> Bool {
            self.storables = self.storables.filter {$0.uuid != uuid}
            return true
        }
        mutating func delete(_ uuids: [UUID]) -> Bool {
            let found = self.storables.filter{ storables.map{ $0.uuid }.contains($0.uuid) }
            guard found.count >= storables.count else { return false }
            self.storables = self.storables.filter { !(uuids.contains($0.uuid)) }
            return true
        }
        
        func count(query: Query?) -> Int {
            return self.fetch(query, sorts: [], limit: 0, offset: 0).count
        }
    }
}

extension InMemoryAdapter: Adapter {
    
    public func connect() -> Future<Bool> { return Future(true) }
    public func disconnect() -> Future<Bool> { return Future(true) }
    
    public func insert<I>(storable: I) -> Future<Bool> where I : Storable {
        var adapterTable = self.store[storable.table.name] ?? AdapterTable()
        guard adapterTable.insert(storable) else { return Future(InMemoryAdapterError.insertFailed) }
        self.store[storable.table.name] = adapterTable
        self.undoStack.push(Stack.Operation(method: .insert, storables: [storable], table: I.table))
        return Future(true)
    }
    public func insert<I>(storables: [I]) -> Future<Bool> where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        guard adapterTable.insert(storables) else { return Future(InMemoryAdapterError.insertFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(Stack.Operation(method: .insert, storables: storables, table: I.table))
        return Future(true)
    }
    
    public func find<I>(uuid: UUID) -> Future<I?> where I : Storable {
        guard let adapterTable = self.store[I.table.name] else { return Future(nil) }
        return Future(adapterTable.find(uuid) as? I)
    }
    public func find<I>(uuids: [UUID], sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> Future<[I]> where I : Storable {
        guard let adapterTable = self.store[I.table.name] else { return Future([]) }
        return Future(adapterTable.find(uuids, sorts: sorts, limit: limit, offset: offset) as? [I] ?? [])
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int) -> Future<[I]> where I : Storable {
        guard let adapterTable = self.store[I.table.name] else { return Future([]) }
        return Future(adapterTable.fetch(query, sorts: sorts, limit: limit, offset: offset) as? [I] ?? [])
    }
    
    public func update<I>(storable: I) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            adapterTable.update(storable)
            else { return Future(InMemoryAdapterError.updateFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(Stack.Operation(method: .update, storables: [storable], table: I.table))
        return Future(true)
    }
    public func update<I>(storables: [I]) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            adapterTable.update(storables)
            else { return Future(InMemoryAdapterError.updateFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(Stack.Operation(method: .update, storables: storables, table: I.table))
        return Future(true)
    }
    
    public func delete<I>(uuid: UUID, type: I.Type) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            let storable = adapterTable.find(uuid),
            adapterTable.delete(uuid)
            else { return Future(InMemoryAdapterError.deleteFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(Stack.Operation(method: .delete, storables: [storable], table: I.table))
        return Future(true)
    }
    public func delete<I>(uuids: [UUID], type: I.Type) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name] else { return Future(InMemoryAdapterError.deleteFailed) }
        let storables = adapterTable.find(uuids)
        guard adapterTable.delete(uuids) else { return Future(InMemoryAdapterError.deleteFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(Stack.Operation(method: .delete, storables: storables, table: I.table))
        return Future(true)
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        guard let adapterTable = self.store[table.name] else { return Future(0) }
        return Future(adapterTable.count(query: query))
    }
    
}

