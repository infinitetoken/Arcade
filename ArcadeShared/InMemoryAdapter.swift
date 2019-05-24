//
//  InMemoryAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import Future

public enum InMemoryAdapterError: Error {
    case insertFailed
    case updateFailed
    case deleteFailed
    case noResult
    case noTable
    case error(error: Error)
}

open class InMemoryAdapter {
    
    private var store: [String : AdapterTable] = [:]
    
    public init() {}
    
    private init(_ store: [String : AdapterTable]) {
        self.store = store
    }
    
}

public extension InMemoryAdapter {
    
    private struct AdapterTable {
        
        var viewables: [Viewable] = []
        
        mutating func insert(_ storable: Storable) -> Bool {
            self.viewables.append(storable)
            return true
        }
        
        mutating func insert(_ storables: [Storable]) -> Bool {
            self.viewables.append(contentsOf: storables)
            return true
        }
        
        func find(_ uuid: String) -> Viewable? { return self.viewables.filter { $0.uuid == uuid }.first }
        
        func find(_ uuids: [String], sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> [Viewable] {
            var storables = self.viewables.filter { uuids.contains($0.uuid) }
            storables = self.sort(viewables: viewables, sorts: sorts)
            return storables.offset(by: offset).limit(to: limit)
        }
        
        func fetch(_ query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> [Viewable] {
            if let query = query {
                var storables = self.viewables.filter { query.evaluate(with: $0) }
                storables = self.sort(viewables: viewables, sorts: sorts)
                return storables.offset(by: offset).limit(to: limit)
            } else {
                return self.sort(viewables: self.viewables, sorts: sorts).offset(by: offset).limit(to: limit)
            }
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
        
        mutating func delete(_ uuid: String) -> Bool {
            self.viewables = self.viewables.filter {$0.uuid != uuid}
            return true
        }
        
        mutating func delete(_ uuids: [String]) -> Bool {
            self.viewables = self.viewables.filter { !(uuids.contains($0.uuid)) }
            return true
        }
        
        func count(query: Query?) -> Int {
            return self.fetch(query, sorts: [], limit: 0, offset: 0).count
        }
        
        func sort(viewables: [Viewable], sorts: [Sort]) -> [Viewable] {
            return sorts.reduce(viewables) { $1.sort(viewables: $0) }
        }
    }
}

extension InMemoryAdapter: Adapter {
    
    public func connect() -> Future<Bool> { return Future(true) }
    public func disconnect() -> Future<Bool> { return Future(true) }
    
    public func insert<I>(storable: I, options: [QueryOption] = []) -> Future<I> where I : Storable {
        var adapterTable = self.store[storable.table.name] ?? AdapterTable()
        guard adapterTable.insert(storable) else { return Future(InMemoryAdapterError.insertFailed) }
        self.store[storable.table.name] = adapterTable

        return Future(storable)
    }
    public func insert<I>(storables: [I], options: [QueryOption] = []) -> Future<[I]> where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        guard adapterTable.insert(storables) else { return Future(InMemoryAdapterError.insertFailed) }
        self.store[I.table.name] = adapterTable

        return Future(storables)
    }
    public func find<I>(uuid: String, options: [QueryOption] = []) -> Future<I> where I : Viewable {
        guard let adapterTable = self.store[I.table.name] else { return Future(InMemoryAdapterError.noTable) }
        
        if let result = adapterTable.find(uuid) as? I {
            return Future(result)
        } else {
            return Future(InMemoryAdapterError.noResult)
        }
    }
    public func find<I>(uuids: [String], sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, options: [QueryOption] = []) -> Future<[I]> where I : Viewable {
        guard let adapterTable = self.store[I.table.name] else { return Future([]) }
        return Future(adapterTable.find(uuids, sorts: sorts, limit: limit, offset: offset) as? [I] ?? [])
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption] = []) -> Future<[I]> where I : Viewable {
        guard let adapterTable = self.store[I.table.name] else { return Future([]) }
        return Future(adapterTable.fetch(query, sorts: sorts, limit: limit, offset: offset) as? [I] ?? [])
    }
    
    public func update<I>(storable: I, options: [QueryOption] = []) -> Future<I> where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            adapterTable.update(storable)
            else { return Future(InMemoryAdapterError.updateFailed) }
        self.store[I.table.name] = adapterTable

        return Future(storable)
    }
    public func update<I>(storables: [I], options: [QueryOption] = []) -> Future<[I]> where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            adapterTable.update(storables)
            else { return Future(InMemoryAdapterError.updateFailed) }
        self.store[I.table.name] = adapterTable

        return Future(storables)
    }
    
    public func delete<I>(uuid: String, type: I.Type, options: [QueryOption] = []) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name], adapterTable.delete(uuid)
            else { return Future(InMemoryAdapterError.deleteFailed) }
        self.store[I.table.name] = adapterTable

        return Future(true)
    }
    public func delete<I>(uuids: [String], type: I.Type, options: [QueryOption] = []) -> Future<Bool> where I : Storable {
        guard var adapterTable = self.store[I.table.name] else { return Future(InMemoryAdapterError.deleteFailed) }
        guard adapterTable.delete(uuids) else { return Future(InMemoryAdapterError.deleteFailed) }
        self.store[I.table.name] = adapterTable

        return Future(true)
    }
    
    public func count<T>(table: T, query: Query?, options: [QueryOption] = []) -> Future<Int> where T : Table {
        guard let adapterTable = self.store[table.name] else { return Future(0) }
        return Future(adapterTable.count(query: query))
    }
    
}

