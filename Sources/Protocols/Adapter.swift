//
//  Adapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import Combine

public protocol Adapter {
    
    func connect(completion: @escaping (Result<Bool, Error>) -> Void)
    func disconnect(completion: @escaping (Result<Bool, Error>) -> Void)
    func insert<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I: Storable
    func find<I>(id: String, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I: Viewable
    func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I: Viewable
    func update<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I: Storable
    func delete<I>(id: String, type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I: Storable
    func count<T>(table: T, query: Query?, options: [QueryOption], completion: @escaping (Result<Int, Error>) -> Void) where T: Table
    
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Adapter {
    
    public typealias Success = Publishers.Future<Bool, Error>
    public typealias Single<I> = Publishers.Future<I, Error>
    public typealias Multiple<I> = Publishers.Future<[I], Error>
    public typealias Count = Publishers.Future<Int, Error>
    
    public func connect() -> Success {
        return Success { promise in
            self.connect { (result) in
                promise(result)
            }
        }
    }
    
    public func disconnect() -> Success {
        return Success { promise in
            self.disconnect { (result) in
                promise(result)
            }
        }
    }
    
    public func insert<I>(storable: I, options: [QueryOption]) -> Single<I> where I: Storable {
        return Single<I> { promise in
            self.insert(storable: storable, options: options) { (result) in
                promise(result)
            }
        }
    }
    
    public func find<I>(id: String, options: [QueryOption]) -> Single<I> where I: Viewable {
        return Single<I> { promise in
            self.find(id: id, options: options) { (result) in
                promise(result)
            }
        }
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption]) -> Multiple<I> where I: Viewable {
        return Multiple<I> { promise in
            self.fetch(query: query, sorts: sorts, limit: limit, offset: offset, options: options) { (result) in
                promise(result)
            }
        }
    }
    
    public func update<I>(storable: I, options: [QueryOption]) -> Single<I> where I: Storable {
        return Single<I> { promise in
            self.update(storable: storable, options: options) { (result) in
                promise(result)
            }
        }
    }
    
    public func delete<I>(id: String, type: I.Type, options: [QueryOption]) -> Success where I: Storable {
        return Success { promise in
            self.delete(id: id, type: type, options: options) { (result) in
                promise(result)
            }
        }
    }
    
    public func count<T>(table: T, query: Query?, options: [QueryOption]) -> Count where T: Table {
        return Count { promise in
            self.count(table: table, query: query, options: options) { (result) in
                promise(result)
            }
        }
    }
    
}
