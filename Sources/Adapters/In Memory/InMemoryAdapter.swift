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
        
        func find(_ id: String) -> Viewable? { return self.viewables.filter { $0.id == id }.first }
        
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
            if let existingStorable = find(storable.id) {
                return delete(existingStorable.id) && insert(storable)
            } else {
                return insert(storable)
            }
        }
        
        mutating func delete(_ id: String) -> Bool {
            self.viewables = self.viewables.filter {$0.id != id}
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
    
    public func find<I>(id: String, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Viewable {
        guard let adapterTable = self.store[I.table.name] else { return completion(.failure(AdapterError.noTable)) }
        
        if let result = adapterTable.find(id) as? I {
            return completion(.success(result))
        } else {
            return completion(.failure(AdapterError.noResult))
        }
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
    
    public func delete<I>(id: String, type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        guard var adapterTable = self.store[I.table.name], adapterTable.delete(id)
            else { return completion(.failure(AdapterError.deleteFailed)) }
        
        self.store[I.table.name] = adapterTable

        return completion(.success(true))
    }
    
    public func count<T>(table: T, query: Query?, options: [QueryOption], completion: @escaping (Result<Int, Error>) -> Void) where T : Table {
        guard let adapterTable = self.store[table.name] else { return completion(.success(0)) }
        
        return completion(.success(adapterTable.count(query: query)))
    }
    
}

