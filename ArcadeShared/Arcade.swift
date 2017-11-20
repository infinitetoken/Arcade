//
//  Arcade.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation



public enum ArcadeError: Error {
    case failedToConnect
}



public struct Arcade<T: Adapter> {

    private let adapter: T
    
    public init(adapter: T) {
        self.adapter = adapter
    }
    
}

extension Arcade: Adapter {
    
    public func connect() -> Future<Arcade> {
        return self.adapter.connect().flatMap { (adapter) -> Future<Arcade> in
            return Future(Arcade(adapter: adapter))
        }
    }
    
    public func disconnect() -> Future<Bool> {
        return self.adapter.disconnect()
    }
    
    public func insert<I, T>(table: T, storable: I) -> Future<Arcade> where I : Storable, T : Table {
        return self.adapter.insert(table: table, storable: storable).flatMap { (adapter) -> Future<Arcade> in
            return Future(Arcade(adapter: adapter))
        }
    }
    
    public func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I : Storable, T : Table {
        return self.adapter.find(table: table, uuid: uuid)
    }
    
    public func fetch<I, T>(table: T, query: Query?) -> Future<[I]> where I : Storable, T : Table {
        return self.adapter.fetch(table: table, query: query)
    }
    
    public func update<I, T>(table: T, storable: I) -> Future<Arcade> where I : Storable, T : Table {
        return self.adapter.update(table: table, storable: storable).flatMap { (adapter) -> Future<Arcade> in
            return Future(Arcade(adapter: adapter))
        }
    }
    
    public func delete<I, T>(table: T, storable: I) -> Future<Arcade> where I : Storable, T : Table {
        return self.adapter.delete(table: table, storable: storable).flatMap { (adapter) -> Future<Arcade> in
            return Future(Arcade(adapter: adapter))
        }
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        return self.adapter.count(table: table, query: query)
    }
    
}
