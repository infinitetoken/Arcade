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
    
    private var undoStack: ActionStack = ActionStack()
    private var redoStack: ActionStack = ActionStack()
    
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
            return (delete(storable.uuid) && insert(storable))
        }
        mutating func update(_ storables: [Storable]) -> Bool {
            let uuids = storables.map{ $0.uuid }
            let found = self.storables.filter{ uuids.contains($0.uuid) }
            guard found.count >= storables.count else { return false }
            return (delete(uuids) && insert(storables))
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
            return self.fetch(query).count
        }
    }
}

extension InMemoryAdapter: Adapter {
    
    public func connect() -> Future<Bool> { return Future(true) }
    public func disconnect() -> Future<Bool> { return Future(true) }
    
    public func undo() -> Future<Bool> {
        guard let table = undoStack.popTable(),
            let operation = undoStack.popOperation(),
            var adapterTable = self.store[table.name]
            else { return Future(false) }
        let storables = undoStack.popStorables()
        
        switch operation {
        case .insert:
            let uuids = storables.map{$0.uuid}
            guard adapterTable.delete(uuids) else { return Future(InMemoryAdapterError.deleteFailed) }
            redoStack.push(storables: storables, operation: .delete, table: table)
        case .update:
            guard adapterTable.update(storables) else { return Future(InMemoryAdapterError.updateFailed) }
            redoStack.push(storables: storables, operation: .update, table: table)
        case .delete:
            guard adapterTable.insert(storables) else { return Future(InMemoryAdapterError.insertFailed) }
            redoStack.push(storables: storables, operation: .insert, table: table)
        }
        
        self.store[table.name] = adapterTable
        return Future(true)
    }
    
    public func redo() -> Future<Bool> {
        guard let table = redoStack.popTable(),
            let operation = redoStack.popOperation(),
            var adapterTable = self.store[table.name]
            else { return Future(false) }
        let storables = redoStack.popStorables()
        
        switch operation {
        case .insert:
            let uuids = storables.map{$0.uuid}
            guard adapterTable.delete(uuids) else { return Future(InMemoryAdapterError.deleteFailed) }
            undoStack.push(storables: storables, operation: .delete, table: table)
        case .update:
            guard adapterTable.update(storables) else { return Future(InMemoryAdapterError.updateFailed) }
            undoStack.push(storables: storables, operation: .update, table: table)
        case .delete:
            guard adapterTable.insert(storables) else { return Future(InMemoryAdapterError.insertFailed) }
            undoStack.push(storables: storables, operation: .insert, table: table)
        }
        
        self.store[table.name] = adapterTable
        return Future(true)
    }
    
    public func insert<I>(storable: I) -> Future<Bool> where I : Storable {
        var adapterTable = self.store[storable.table.name] ?? AdapterTable()
        guard adapterTable.insert(storable) else { return Future(InMemoryAdapterError.insertFailed) }
        self.store[storable.table.name] = adapterTable
        self.undoStack.push(storables: [storable], operation: .insert, table: storable.table)
        return Future(true)
    }
    public func insert<I>(storables: [I]) -> Future<Bool> where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        guard adapterTable.insert(storables) else { return Future(InMemoryAdapterError.insertFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(storables: storables, operation: .insert, table: I.table)
        return Future(true)
    }
    
    public func find<I>(uuid: UUID) -> Future<I?> where I : Storable {
        guard let adapterTable = self.store[I.table.name] else { return Future(nil) }
        return Future(adapterTable.find(uuid) as? I)
    }
    public func find<I>(uuids: [UUID]) -> Future<[I]> where I : Storable {
        guard let adapterTable = self.store[I.table.name] else { return Future([]) }
        return Future(adapterTable.find(uuids) as? [I] ?? [])
    }
    
    public func fetch<I>(query: Query?) -> Future<[I]> where I : Storable {
        guard let adapterTable = self.store[I.table.name] else { return Future([]) }
        return Future(adapterTable.fetch(query) as? [I] ?? [])
    }
    
    public func update<I>(storable: I) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            adapterTable.update(storable)
            else { return Future(InMemoryAdapterError.updateFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(storables: [storable], operation: .update, table: I.table)
        return Future(true)
    }
    public func update<I>(storables: [I]) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            adapterTable.update(storables)
            else { return Future(InMemoryAdapterError.updateFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(storables: storables, operation: .update, table: I.table)
        return Future(true)
    }
    
    public func delete<I>(uuid: UUID, type: I.Type) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            let storable = adapterTable.find(uuid),
            adapterTable.delete(uuid)
            else { return Future(InMemoryAdapterError.deleteFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(storables: [storable], operation: .delete, table: I.table)
        return Future(true)
    }
    public func delete<I>(uuids: [UUID], type: I.Type) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name] else { return Future(InMemoryAdapterError.deleteFailed) }
        let storables = adapterTable.find(uuids)
        guard adapterTable.delete(uuids) else { return Future(InMemoryAdapterError.deleteFailed) }
        self.store[I.table.name] = adapterTable
        self.undoStack.push(storables: storables, operation: .delete, table: I.table)
        return Future(true)
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        guard let adapterTable = self.store[table.name] else { return Future(0) }
        return Future(adapterTable.count(query: query))
    }
    
}

