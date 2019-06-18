//
//  InMemoryAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

open class InMemoryAdapter {
    
    public enum AdapterError: LocalizedError {
        case insertFailed
        case updateFailed
        case deleteFailed
        case noResult
        case noTable
        case notSupported
        case error(error: Error)
        
        public var errorDescription: String? {
            switch self {
            case .insertFailed:
                return "Insert failed"
            case .updateFailed:
                return "Update failed"
            case .deleteFailed:
                return "Delete failed"
            case .noResult:
                return "No result"
            case .noTable:
                return "No table"
            case .notSupported:
                return "Not supported"
            case .error(let error):
                return error.localizedDescription
            }
        }
    }
    
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
    
    public func connect(completion: @escaping (Result<Bool, Error>) -> Void) { return completion(.failure(AdapterError.notSupported)) }
    public func disconnect(completion: @escaping (Result<Bool, Error>) -> Void) { return completion(.failure(AdapterError.notSupported)) }
    
    public func insert<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Storable {
        var adapterTable = self.store[storable.table.name] ?? AdapterTable()
        guard adapterTable.insert(storable) else { return completion(.failure(AdapterError.insertFailed)) }
        
        self.store[storable.table.name] = adapterTable

        return completion(.success(storable))
    }
    
    public func insert<I>(storables: [I], options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        guard adapterTable.insert(storables) else { return completion(.failure(AdapterError.insertFailed)) }
        
        self.store[I.table.name] = adapterTable

        return completion(.success(storables))
    }
    
    public func find<I>(uuid: String, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Viewable {
        guard let adapterTable = self.store[I.table.name] else { return completion(.failure(AdapterError.noTable)) }
        
        if let result = adapterTable.find(uuid) as? I {
            return completion(.success(result))
        } else {
            return completion(.failure(AdapterError.noResult))
        }
    }
    
    public func find<I>(uuids: [String], sorts: [Sort], limit: Int, offset: Int, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Viewable {
        guard let adapterTable = self.store[I.table.name] else { return completion(.success([])) }
        
        return completion(.success(adapterTable.find(uuids, sorts: sorts, limit: limit, offset: offset) as? [I] ?? []))
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Viewable {
        guard let adapterTable = self.store[I.table.name] else { return completion(.success([])) }
        
        return completion(.success(adapterTable.fetch(query, sorts: sorts, limit: limit, offset: offset) as? [I] ?? []))
    }
    
    public func update<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            adapterTable.update(storable)
            else { return completion(.failure(AdapterError.updateFailed)) }
        
        self.store[I.table.name] = adapterTable

        return completion(.success(storable))
    }
    
    public func update<I>(storables: [I], options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Storable {
        guard var adapterTable = self.store[I.table.name],
            adapterTable.update(storables)
            else { return completion(.failure(AdapterError.updateFailed)) }
        
        self.store[I.table.name] = adapterTable

        return completion(.success(storables))
    }
    
    public func delete<I>(uuid: String, type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        guard var adapterTable = self.store[I.table.name], adapterTable.delete(uuid)
            else { return completion(.failure(AdapterError.deleteFailed)) }
        
        self.store[I.table.name] = adapterTable

        return completion(.success(true))
    }
    
    public func delete<I>(uuids: [String], type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        guard var adapterTable = self.store[I.table.name] else { return completion(.failure(AdapterError.deleteFailed)) }
        guard adapterTable.delete(uuids) else { return completion(.failure(AdapterError.deleteFailed)) }
        
        self.store[I.table.name] = adapterTable

        return completion(.success(true))
    }
    
    public func count<T>(table: T, query: Query?, options: [QueryOption], completion: @escaping (Result<Int, Error>) -> Void) where T : Table {
        guard let adapterTable = self.store[table.name] else { return completion(.success(0)) }
        
        return completion(.success(adapterTable.count(query: query)))
    }
    
}

