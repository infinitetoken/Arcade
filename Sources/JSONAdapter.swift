//
//  JSONAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/17/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

open class JSONAdapter {
    
    public enum AdapterError: LocalizedError {
        case insertFailed
        case updateFailed
        case deleteFailed
        case saveFailed
        case encodeFailed(error: Error)
        case decodeFailed(error: Error)
        case noDirectory
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
            case .saveFailed:
                return "Save failed"
            case .encodeFailed(let error):
                return "Encode failed: \(error.localizedDescription)"
            case .decodeFailed(let error):
                return "Decode failed: \(error.localizedDescription)"
            case .noTable:
                return "No table"
            case .noDirectory:
                return "No directory"
            case .noResult:
                return "No result"
            case .notSupported:
                return "Not supported"
            case .error(let error):
                return error.localizedDescription
            }
        }
    }
    
    private var store: [String : AdapterTable] = [:]
    private var directory: URL?
    
    private var operationQueue: OperationQueue
    
    public var prettyPrinted: Bool = true
    
    public init(directory: URL) {
        self.directory = directory
        self.operationQueue = OperationQueue.init()
        self.operationQueue.maxConcurrentOperationCount = 1
    }
    
    private init(_ store: [String : AdapterTable], directory: URL?) {
        self.store = store
        self.directory = directory
        self.operationQueue = OperationQueue.init()
        self.operationQueue.maxConcurrentOperationCount = 1
    }
    
}

public extension JSONAdapter {
    
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
        
        func find(_ uuid: String) -> Viewable? { return viewables.filter { $0.uuid == uuid }.first }
        func find(_ uuids: [String], sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> [Viewable] {
            var viewables = self.viewables.filter { uuids.contains($0.uuid) }
            viewables = self.sort(viewables: viewables, sorts: sorts)
            return viewables.offset(by: offset).limit(to: limit)
        }
        
        func fetch(_ query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> [Viewable] {
            if let query = query {
                var viewables = self.viewables.filter { query.evaluate(with: $0) }
                viewables = self.sort(viewables: viewables, sorts: sorts)
                return viewables.offset(by: offset).limit(to: limit)
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
            viewables = viewables.filter { $0.uuid != uuid }
            return true
        }
        mutating func delete(_ uuids: [String]) -> Bool {
            viewables = viewables.filter { !(uuids.contains($0.uuid)) }
            return true
        }
        
        func count(query: Query?) -> Int {
            return self.fetch(query, sorts: [], limit: 0, offset: 0).count
        }
        
        func sort(viewables: [Viewable], sorts: [Sort]) -> [Viewable] {
            if sorts.isEmpty { return viewables }
            
            var _viewables = viewables
            
            for sort in sorts {
                _viewables = sort.sort(viewables: _viewables)
            }
            
            return _viewables
        }
    }
    
}

extension JSONAdapter: Adapter {
    
    public func connect(completion: @escaping (Result<Bool, Error>) -> Void) { return completion(.failure(AdapterError.notSupported)) }
    public func disconnect(completion: @escaping (Result<Bool, Error>) -> Void) { return completion(.failure(AdapterError.notSupported)) }
    
    public func insert<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        let table = I.table
        
        guard adapterTable.insert(storable) else { completion(.failure(AdapterError.insertFailed)); return }
        
        self.store[table.name] = adapterTable
        
        self.save(storables: adapterTable.viewables as! [I]) { (result) in
            switch result {
            case .success(_): completion(.success(storable))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    public func insert<I>(storables: [I], options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        
        guard adapterTable.insert(storables) else { completion(.failure(AdapterError.insertFailed)); return }
        
        self.store[I.table.name] = adapterTable
        
        self.save(storables: adapterTable.viewables as! [I]) { (result) in
            switch result {
            case .success(_): completion(.success(storables))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    public func find<I>(uuid: String, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Viewable {
        self.load() { (result: Result<[I], Error>) in
            switch result {
            case .success(let viewables):
                let adapterTable = AdapterTable(viewables: viewables)
                self.store[I.table.name] = adapterTable
                if let result = adapterTable.find(uuid) as? I {
                    completion(.success(result))
                } else {
                    completion(.failure(AdapterError.noResult))
                }
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    public func find<I>(uuids: [String], sorts: [Sort], limit: Int, offset: Int, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Viewable {
        self.load() { (result: Result<[I], Error>) in
            switch result {
            case .success(let viewables):
                let adapterTable = AdapterTable(viewables: viewables)
                self.store[I.table.name] = adapterTable
                completion(.success(adapterTable.find(uuids, sorts: sorts, limit: limit, offset: offset) as? [I] ?? []))
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    public func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Viewable {
        self.load() { (result: Result<[I], Error>) in
            switch result {
            case .success(let viewables):
                let adapterTable = AdapterTable(viewables: viewables)
                self.store[I.table.name] = adapterTable
                completion(.success(adapterTable.fetch(query, sorts: sorts, limit: limit, offset: offset) as! [I]))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    public func update<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        
        guard adapterTable.update(storable) else { completion(.failure(AdapterError.updateFailed)); return }
        
        self.store[I.table.name] = adapterTable
        
        self.save(storables: adapterTable.viewables as! [I]) { (result) in
            switch result {
            case .success(_): completion(.success(storable))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    public func update<I>(storables: [I], options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        
        guard adapterTable.update(storables) else { completion(.failure(AdapterError.updateFailed)); return }
        
        self.store[I.table.name] = adapterTable
        
        self.save(storables: adapterTable.viewables as! [I]) { (result) in
            switch result {
            case .success(_): completion(.success(storables))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    public func delete<I>(uuid: String, type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        guard let _ = adapterTable.find(uuid),
            adapterTable.delete(uuid)
            else { completion(.failure(AdapterError.deleteFailed)); return }
        
        self.store[I.table.name] = adapterTable
        
        self.save(storables: adapterTable.viewables as! [I]) { (result) in
            switch result {
            case .success(let success): completion(.success(success))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    public func delete<I>(uuids: [String], type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        var adapterTable = self.store[I.table.name] ?? AdapterTable()
        guard adapterTable.delete(uuids) else { completion(.failure(AdapterError.deleteFailed)); return }
        
        self.store[I.table.name] = adapterTable
        
        self.save(storables: adapterTable.viewables as! [I]) { (result) in
            switch result {
            case .success(let success): completion(.success(success))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    public func count<T>(table: T, query: Query?, options: [QueryOption], completion: @escaping (Result<Int, Error>) -> Void) where T : Table {
        guard let adapterTable = self.store[table.name] else { completion(.success(0)); return }
        
        completion(.success(adapterTable.count(query: query)))
    }
    
    private func save<I>(storables: [I], options: [QueryOption] = [], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        self.operationQueue.addOperation {
            guard let directory = self.directory else { completion(.failure(AdapterError.noDirectory)); return }
            
            let encoder = JSONEncoder()
            encoder.dataEncodingStrategy = .base64
            encoder.dateEncodingStrategy = .secondsSince1970
            encoder.keyEncodingStrategy = .convertToSnakeCase
            
            if self.prettyPrinted {
                encoder.outputFormatting = .prettyPrinted
            }
            
            do {
                let fileURL = directory.appendingPathComponent("\(I.table.name).json")
                
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: fileURL.path) {
                    let array: [String] = []
                    let data = try encoder.encode(array)
                    
                    fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
                }
                
                let data = try encoder.encode(storables)
                try data.write(to: fileURL)
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func load<I>(completion: @escaping (Result<[I], Error>) -> Void) where I : Viewable {
        guard let directory = self.directory else { completion(.failure(AdapterError.noDirectory)); return }
        
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileURL = directory.appendingPathComponent("\(I.table.name).json")
                
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: fileURL.path) {
                    let array: [String] = []
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(array)
                    
                    fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
                }
                
                let data = try Data(contentsOf: fileURL)
                let storables = try decoder.decode([I].self, from: data)
                DispatchQueue.main.async {
                    completion(.success(storables))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
}
