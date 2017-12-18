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

public final class JSONAdapter {
    
    private var store: [String : AdapterTable] = [:]
    private var directory: URL?
    
    private var undoStack: ActionStack = ActionStack()
    private var redoStack: ActionStack = ActionStack()
    
    public var prettyPrinted: Bool = false
    
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
        func find(_ uuids: [UUID]) -> [Storable] { return storables.filter { uuids.contains($0.uuid) } }
        
        func fetch(_ query: Query?) -> [Storable] {
            guard let query = query else { return storables }
            return storables.filter { $0.query(query: query) }
        }
        
        mutating func update(_ storable: Storable) -> Bool {
            guard let existingStorable = find(storable.uuid) else { return false }
            return (delete(existingStorable.uuid) && insert(storable))
        }
        mutating func update(_ storables: [Storable]) -> Bool {
            let found = self.storables.filter{ storables.map{ $0.uuid }.contains($0.uuid) }
            guard found.count >= storables.count else { return false }
            return (delete(storables.map{ $0.uuid }) && insert(storables))
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
            return self.fetch(query).count
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
        
        return Future<Bool> { completion in
            guard let directory = self.directory else { completion(.failure(JSONAdapterError.noDirectory)); return }
            let encoder = JSONEncoder()
            if self.prettyPrinted { encoder.outputFormatting = .prettyPrinted }
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try encoder.encode(adapterTable.storables)
                    try data.write(to: directory.appendingPathComponent("\(table.name).json"))
                    DispatchQueue.main.async {
                        self.store[table.name] = adapterTable
                        completion(.success(true))
                    }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
        }
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
        
        return Future<Bool> { completion in
            guard let directory = self.directory else { completion(.failure(JSONAdapterError.noDirectory)); return }
            let encoder = JSONEncoder()
            if self.prettyPrinted { encoder.outputFormatting = .prettyPrinted }
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try encoder.encode(adapterTable.storables)
                    try data.write(to: directory.appendingPathComponent("\(table.name).json"))
                    DispatchQueue.main.async {
                        self.store[table.name] = adapterTable
                        completion(.success(true))
                    }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
        }
    }
    
    public func insert<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { completion in
            var adapterTable = self.store[table.name] ?? AdapterTable()
            
            guard adapterTable.insert(storable) else { completion(.failure(JSONAdapterError.insertFailed)); return }
            
            self.save(table: table, storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[table.name] = adapterTable
                self.undoStack.push(storables: [storable], operation: .insert, table: table)
                completion(.success(success))
            }) { (error) in
                completion(.failure(error))
            }
        }
    }
    
    public func insert<I, T>(table: T, storables: [I]) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { completion in
            var adapterTable = self.store[table.name] ?? AdapterTable()
            
            guard adapterTable.insert(storables) else { completion(.failure(JSONAdapterError.insertFailed)); return }
            
            self.save(table: table, storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[table.name] = adapterTable
                self.undoStack.push(storables: storables, operation: .insert, table: table)
                completion(.success(success))
            }) { (error) in
                completion(.failure(error))
            }
        }
    }
    
    public func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I : Storable, T : Table {
        return Future<I?> { completion in
            self.load(table: table).subscribe({ (storables: [I]) in
                let adapterTable = AdapterTable(storables: storables)
                self.store[table.name] = adapterTable
                completion(.success(adapterTable.find(uuid) as? I))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func find<I, T>(table: T, uuids: [UUID]) -> Future<[I]> where I : Storable, T : Table {
        return Future<[I]> { completion in
            self.load(table: table).subscribe({ (storables: [I]) in
                let adapterTable = AdapterTable(storables: storables)
                self.store[table.name] = adapterTable
                completion(.success(adapterTable.find(uuids) as? [I] ?? []))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func fetch<I, T>(table: T, query: Query?) -> Future<[I]> where I : Storable, T : Table {
        return Future<[I]> { completion in
            self.load(table: table).subscribe({ (storables: [I]) in
                let adapterTable = AdapterTable(storables: storables)
                self.store[table.name] = adapterTable
                completion(.success(adapterTable.fetch(query) as! [I]))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func update<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { completion in
            var adapterTable = self.store[table.name] ?? AdapterTable()
            
            guard adapterTable.update(storable) else { completion(.failure(JSONAdapterError.updateFailed)); return }
            
            self.save(table: table, storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[table.name] = adapterTable
                self.undoStack.push(storables: [storable], operation: .update, table: table)
                completion(.success(success))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func update<I, T>(table: T, storables: [I]) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { completion in
            var adapterTable = self.store[table.name] ?? AdapterTable()
            
            guard adapterTable.update(storables) else { completion(.failure(JSONAdapterError.updateFailed)); return }
            
            self.save(table: table, storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[table.name] = adapterTable
                self.undoStack.push(storables: storables, operation: .update, table: table)
                completion(.success(success))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func delete<I, T>(table: T, uuid: UUID, type: I.Type) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { completion in
            var adapterTable = self.store[table.name] ?? AdapterTable()
            guard let storable = adapterTable.find(uuid),
                adapterTable.delete(uuid)
                else { completion(.failure(JSONAdapterError.deleteFailed)); return }
            self.save(table: table, storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.store[table.name] = adapterTable
                self.undoStack.push(storables: [storable], operation: .delete, table: table)
                completion(.success(success))
            }, { (error) in
                completion(.failure(error))
            })
        }
    }
    
    public func delete<I, T>(table: T, uuids: [UUID], type: I.Type) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { completion in
            var adapterTable = self.store[table.name] ?? AdapterTable()
            let storables = adapterTable.find(uuids)
            guard adapterTable.delete(uuids) else { completion(.failure(JSONAdapterError.deleteFailed)); return }
            
            self.save(table: table, storables: adapterTable.storables as! [I]).subscribe({ (success) in
                self.undoStack.push(storables: storables, operation: .delete, table: table)
                self.store[table.name] = adapterTable
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
    
    private func save<I, T>(table: T, storables: [I]) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { completion in
            guard let directory = self.directory else { completion(.failure(JSONAdapterError.noDirectory)); return }
            
            let encoder = JSONEncoder()
            
            if self.prettyPrinted {
                encoder.outputFormatting = .prettyPrinted
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let fileURL = directory.appendingPathComponent("\(table.name).json")
                    
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
    
    private func load<I, T>(table: T) -> Future<[I]> where I : Storable, T : Table {
        return Future<[I]> { completion in
            guard let directory = self.directory else { completion(.failure(JSONAdapterError.noDirectory)); return }
            
            let decoder = JSONDecoder()

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let fileURL = directory.appendingPathComponent("\(table.name).json")
                    
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
