//
//  Adapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public protocol Adapter {
    
    func connect() -> Future<Bool>
    func disconnect() -> Future<Bool>
    func insert<I, T>(table: T, storable: I) -> Future<Bool> where I: Storable, T: Table
    func insert<I, T>(table: T, storables: [I]) -> Future<Bool> where I: Storable, T: Table
    func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I: Storable, T: Table
    func find<I, T>(table: T, uuids: [UUID]) -> Future<[I]> where I: Storable, T: Table
    func fetch<I, T>(_ table: T) -> Future<[I]> where I: Storable, T: Table
    func fetch<I, T>(table: T, query: Query?) -> Future<[I]> where I: Storable, T: Table
    func update<I, T>(table: T, storable: I) -> Future<Bool> where I: Storable, T: Table
    func update<I, T>(table: T, storables: [I]) -> Future<Bool> where I: Storable, T: Table
    func delete<I, T>(table: T, uuid: UUID, type: I.Type) -> Future<Bool> where I: Storable, T: Table
    func delete<I, T>(table: T, uuids: [UUID], type: I.Type) -> Future<Bool> where I: Storable, T: Table
    func count<T>(_ table: T) -> Future<Int> where T: Table
    func count<T>(table: T, query: Query?) -> Future<Int> where T: Table
    
}

extension Adapter {
    
    public func fetch<I, T>(_ table: T) -> Future<[I]> where I: Storable, T: Table {
        return self.fetch(table: table, query: nil)
    }
    
    public func count<T>(_ table: T) -> Future<Int> where T: Table {
        return self.count(table: table, query: nil)
    }
    
}
