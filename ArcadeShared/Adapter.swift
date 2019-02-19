//
//  Adapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import Future

public protocol Adapter {
    
    func connect() -> Future<Bool>
    func disconnect() -> Future<Bool>
    func insert<I>(storable: I, options: [QueryOption]) -> Future<I> where I: Storable
    func insert<I>(storables: [I], options: [QueryOption]) -> Future<[I]> where I: Storable
    func find<I>(uuid: String, options: [QueryOption]) -> Future<I?> where I: Storable
    func find<I>(uuids: [String], sorts: [Sort], limit: Int, offset: Int, options: [QueryOption]) -> Future<[I]> where I: Storable
    func fetch<I>(options: [QueryOption]) -> Future<[I]> where I: Storable
    func fetch<I>(query: Query?, options: [QueryOption]) -> Future<[I]> where I: Storable
    func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption]) -> Future<[I]> where I: Storable
    func update<I>(storable: I, options: [QueryOption]) -> Future<I> where I: Storable
    func update<I>(storables: [I], options: [QueryOption]) -> Future<[I]> where I: Storable
    func delete<I>(uuid: String, type: I.Type, options: [QueryOption]) -> Future<Bool> where I: Storable
    func delete<I>(uuids: [String], type: I.Type, options: [QueryOption]) -> Future<Bool> where I: Storable
    func count<T>(table: T, options: [QueryOption]) -> Future<Int> where T: Table
    func count<T>(table: T, query: Query?, options: [QueryOption]) -> Future<Int> where T: Table
    
}

extension Adapter {
    
    public func fetch<I>(options: [QueryOption] = []) -> Future<[I]> where I: Storable {
        return self.fetch(query: nil, options: options)
    }
    
    public func fetch<I>(query: Query?, options: [QueryOption] = []) -> Future<[I]> where I: Storable {
        return self.fetch(query: query, sorts: [], limit: 0, offset: 0, options: options)
    }
    
    public func count<T>(table: T, options: [QueryOption] = []) -> Future<Int> where T: Table {
        return self.count(table: table, query: nil, options: options)
    }
    
}
