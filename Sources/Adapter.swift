//
//  Adapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public protocol Adapter {
    
    func connect(completion: @escaping (Result<Bool, Error>) -> Void)
    func disconnect(completion: @escaping (Result<Bool, Error>) -> Void)
    func insert<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I: Storable
    func insert<I>(storables: [I], options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I: Storable
    func find<I>(uuid: String, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I: Viewable
    func find<I>(uuids: [String], sorts: [Sort], limit: Int, offset: Int, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I: Viewable
    func fetch<I>(options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I: Viewable
    func fetch<I>(query: Query?, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I: Viewable
    func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I: Viewable
    func update<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I: Storable
    func update<I>(storables: [I], options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I: Storable
    func delete<I>(uuid: String, type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I: Storable
    func delete<I>(uuids: [String], type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I: Storable
    func count<T>(table: T, options: [QueryOption], completion: @escaping (Result<Int, Error>) -> Void) where T: Table
    func count<T>(table: T, query: Query?, options: [QueryOption], completion: @escaping (Result<Int, Error>) -> Void) where T: Table
    
}

extension Adapter {
    
    public func fetch<I>(options: [QueryOption] = [], completion: @escaping (Result<[I], Error>) -> Void) where I: Viewable {
        return self.fetch(query: nil, options: options, completion: completion)
    }
    
    public func fetch<I>(query: Query?, options: [QueryOption] = [], completion: @escaping (Result<[I], Error>) -> Void) where I: Viewable {
        return self.fetch(query: query, sorts: [], limit: 0, offset: 0, options: options, completion: completion)
    }
    
    public func count<T>(table: T, options: [QueryOption] = [], completion: @escaping (Result<Int, Error>) -> Void) where T: Table {
        return self.count(table: table, query: nil, options: options, completion: completion)
    }
    
}
