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
    case noDirectory
    case noResult
    case error(error: Error)
}

open class JSONAdapter {
    
    private var store: [String : AdapterTable] = [:]
    private var directory: URL?
    
    public var prettyPrinted: Bool = true
    
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
        mutating func insert(_ storables: [Storable]) -> Bool {
            self.storables.append(contentsOf: storables)
            return true
        }
        
        func find(_ uuid: UUID) -> Storable? { return storables.filter { $0.uuid == uuid }.first }
        func find(_ uuids: [UUID], sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> [Storable] {
            var storables = self.storables.filter { uuids.contains($0.uuid) }
            storables = self.sort(storables: storables, sorts: sorts)
            return storables.offset(by: offset).limit(to: limit)
        }
        
        func fetch(_ query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> [Storable] {
            if let query = query {
                var storables = self.storables.filter { query.predicate().evaluate(with: $0.dictionary) }
                storables = self.sort(storables: storables, sorts: sorts)
                return storables.offset(by: offset).limit(to: limit)
            } else {
                return self.sort(storables: self.storables, sorts: sorts).offset(by: offset).limit(to: limit)
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
        
        mutating func delete(_ uuid: UUID) -> Bool {
            storables = storables.filter { $0.uuid != uuid }
            return true
        }
        mutating func delete(_ uuids: [UUID]) -> Bool {
            storables = storables.filter { !(uuids.contains($0.uuid)) }
            return true
        }
        
        func count(query: Query?) -> Int {
            return self.fetch(query, sorts: [], limit: 0, offset: 0).count
        }
        
        func sort(storables: [Storable], sorts: [Sort]) -> [Storable] {
            if sorts.isEmpty { return storables }
            
            var _storables = storables
            
            for sort in sorts {
                _storables = self.sort(storables: _storables, sort: sort)
            }
            
            return _storables
        }
        
        func sort(storables: [Storable], sort: Sort) -> [Storable] {
            let dicts = storables.map { (storable) -> [String : Any] in
                return storable.dictionary
            }
            
            let sorted = zip(dicts, storables).sorted { (a, b) -> Bool in
                switch sort.sortDescriptor().compare(a.0, to: b.0) {
                case .orderedAscending:
                    return true
                case .orderedDescending:
                    return false
                case .orderedSame:
                    return true
                }
            }
            
            return sorted.map { $0.1 }
        }
        
    }
    
}

extension JSONAdapter: Adapter {
    
    public func connect() -> Future<Bool> {
        return Future(true)
    }
    
    public func disconnect() -> Future<Bool> {
        return Future(true)
    }
    
    public func insert<I>(storable: I) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            var adapterTable = self.store[I.table.name] ?? AdapterTable()
            let table = I.table
            
            guard adapterTable.insert(storable) else { completion(.failure(JSONAdapterError.insertFailed)); return }
            
            self.save(storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[table.name] = adapterTable
                completion(.success(success))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func insert<I>(storables: [I]) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            var adapterTable = self.store[I.table.name] ?? AdapterTable()
            
            guard adapterTable.insert(storables) else { completion(.failure(JSONAdapterError.insertFailed)); return }
            
            self.save(storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[I.table.name] = adapterTable
                completion(.success(success))
            }) { (error) in
                completion(.failure(error))
            }
        }
    }
    
    public func find<I>(uuid: UUID) -> Future<I?> where I : Storable {
        return Future<I?> { completion in
            self.load().subscribe({ (storables: [I]) in
                let adapterTable = AdapterTable(storables: storables)
                self.store[I.table.name] = adapterTable
                completion(.success(adapterTable.find(uuid) as? I))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func find<I>(uuids: [UUID], sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> Future<[I]> where I : Storable {
        return Future<[I]> { completion in
            self.load().subscribe({ (storables: [I]) in
                let adapterTable = AdapterTable(storables: storables)
                self.store[I.table.name] = adapterTable
                completion(.success(adapterTable.find(uuids, sorts: sorts, limit: limit, offset: offset) as? [I] ?? []))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> Future<[I]> where I : Storable {
        return Future<[I]> { completion in
            self.load().subscribe({ (storables: [I]) in
                let adapterTable = AdapterTable(storables: storables)
                self.store[I.table.name] = adapterTable
                completion(.success(adapterTable.fetch(query, sorts: sorts, limit: limit, offset: offset) as! [I]))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func update<I>(storable: I) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            var adapterTable = self.store[I.table.name] ?? AdapterTable()
            
            guard adapterTable.update(storable) else { completion(.failure(JSONAdapterError.updateFailed)); return }
            
            self.save(storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[I.table.name] = adapterTable
                completion(.success(success))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func update<I>(storables: [I]) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            var adapterTable = self.store[I.table.name] ?? AdapterTable()
            
            guard adapterTable.update(storables) else { completion(.failure(JSONAdapterError.updateFailed)); return }
            
            self.save(storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[I.table.name] = adapterTable
                completion(.success(success))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func delete<I>(uuid: UUID, type: I.Type) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            var adapterTable = self.store[I.table.name] ?? AdapterTable()
            guard let _ = adapterTable.find(uuid),
                adapterTable.delete(uuid)
                else { completion(.failure(JSONAdapterError.deleteFailed)); return }
            self.save(storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[I.table.name] = adapterTable
                completion(.success(success))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func delete<I>(uuids: [UUID], type: I.Type) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            var adapterTable = self.store[I.table.name] ?? AdapterTable()
            guard adapterTable.delete(uuids) else { completion(.failure(JSONAdapterError.deleteFailed)); return }
            
            self.save(storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[I.table.name] = adapterTable
                completion(.success(success))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        return Future<Int> { completion in
            guard let adapterTable = self.store[table.name] else { completion(.success(0)); return }
            
            completion(.success(adapterTable.count(query: query)))
        }
    }
    
    private func save<I>(storables: [I]) -> Future<Bool> where I : Storable {
        return Future<Bool> { completion in
            guard let directory = self.directory else { completion(.failure(JSONAdapterError.noDirectory)); return }
            
            let encoder = JSONEncoder()
            encoder.dataEncodingStrategy = .base64
            encoder.dateEncodingStrategy = .secondsSince1970
            encoder.keyEncodingStrategy = .convertToSnakeCase
            
            if self.prettyPrinted {
                encoder.outputFormatting = .prettyPrinted
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
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
    }
    
    private func load<I>() -> Future<[I]> where I : Storable {
        return Future<[I]> { completion in
            guard let directory = self.directory else { completion(.failure(JSONAdapterError.noDirectory)); return }
            
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
    
}
