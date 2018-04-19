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
    func insert<I>(storable: I) -> Future<Bool> where I: Storable
    func insert<I>(storables: [I]) -> Future<Bool> where I: Storable
    func find<I>(uuid: UUID) -> Future<I?> where I: Storable
    func find<I>(uuids: [UUID], sorts: [Sort], limit: Int, offset: Int) -> Future<[I]> where I: Storable
    func fetch<I>() -> Future<[I]> where I: Storable
    func fetch<I>(query: Query?) -> Future<[I]> where I: Storable
    func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int) -> Future<[I]> where I: Storable
    func update<I>(storable: I) -> Future<Bool> where I: Storable
    func update<I>(storables: [I]) -> Future<Bool> where I: Storable
    func delete<I>(uuid: UUID, type: I.Type) -> Future<Bool> where I: Storable
    func delete<I>(uuids: [UUID], type: I.Type) -> Future<Bool> where I: Storable
    func count<T>(table: T) -> Future<Int> where T: Table
    func count<T>(table: T, query: Query?) -> Future<Int> where T: Table
    
}

extension Adapter {
    
    public func fetch<I>() -> Future<[I]> where I: Storable {
        return self.fetch(query: nil)
    }
    
    public func fetch<I>(query: Query?) -> Future<[I]> where I: Storable {
        return self.fetch(query: query, sorts: [], limit: 0, offset: 0)
    }
    
    public func count<T>(table: T) -> Future<Int> where T: Table {
        return self.count(table: table, query: nil)
    }
    
}
