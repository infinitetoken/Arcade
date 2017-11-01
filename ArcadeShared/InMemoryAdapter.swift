//
//  InMemoryAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public class InMemoryAdapter {
    
    private var store: [String : AdapterTable?] = [:]
    
}

extension InMemoryAdapter {
    
    private class AdapterTable {
        var storables: [Storable] = []
        
        func insert(storable: Storable) -> Bool {
            self.storables.append(storable)
            return true
        }
        
        func find(uuid: UUID) -> Storable? {
            return self.storables.filter { (storable) -> Bool in
                return storable.uuid == uuid
            }.first
        }
        
        func fetch(query: Query?) -> [Storable] {
            if let query = query {
                return self.storables.filter({ (storable) -> Bool in
                    return storable.query(query: query)
                })
            } else {
                return self.storables
            }
        }
        
        func update(storable: Storable) -> Bool {
            if let existingStorable = self.find(uuid: storable.uuid) {
                if self.delete(storable: existingStorable) && self.insert(storable: storable) {
                    return true
                }
                return false
            } else {
                return false
            }
        }
        
        func delete(storable: Storable) -> Bool {
            if let storable = self.find(uuid: storable.uuid) {
                self.storables = self.storables.filter { (existing) -> Bool in
                    return existing.uuid != storable.uuid
                }
                return true
            } else {
                return false
            }
        }
        
        func count(query: Query?) -> Int {
            return self.fetch(query: query).count
        }
    }
    
}

extension InMemoryAdapter: Adapter {
    
    public func connect() -> Future<Bool> {
        return Future(value: true)
    }
    
    public func disconnect() -> Future<Bool> {
        return Future(value: true)
    }
    
    public func insert<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        return Future<Bool> { operation in
            if let adapterTable = self.store[table.name] as? AdapterTable {
                operation(Result.success(adapterTable.insert(storable: storable)))
            } else {
                let adapterTable = AdapterTable()
                self.store[table.name] = adapterTable
                operation(Result.success(adapterTable.insert(storable: storable)))
            }
        }
    }
    
    public func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I : Storable, T : Table {
        if let adapterTable = self.store[table.name] as? AdapterTable {
            return Future(value: adapterTable.find(uuid: uuid) as? I)
        } else {
            return Future(value: nil)
        }
    }
    
    public func fetch<I, T>(table: T, query: Query?) -> Future<[I]> where I : Storable, T : Table {
        if let adapterTable = self.store[table.name] as? AdapterTable {
            return Future(value: adapterTable.fetch(query: query) as! [I])
        } else {
            return Future(value: [])
        }
    }
    
    public func update<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        if let adapterTable = self.store[table.name] as? AdapterTable {
            return Future(value: adapterTable.update(storable: storable))
        } else {
            return Future(value: false)
        }
    }
    
    public func delete<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        if let adapterTable = self.store[table.name] as? AdapterTable {
            return Future(value: adapterTable.delete(storable: storable))
        } else {
            return Future(value: false)
        }
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        if let adapterTable = self.store[table.name] as? AdapterTable {
            return Future(value: adapterTable.count(query: query))
        } else {
            return Future(value: 0)
        }
    }
    
}
