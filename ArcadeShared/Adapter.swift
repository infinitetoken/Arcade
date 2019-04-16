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
    func connect(condition: Bool) -> Future<(Bool?, Bool)>
    
    func disconnect() -> Future<Bool>
    func disconnect(condition: Bool) -> Future<(Bool?, Bool)>
    
    func insert<I>(storable: I, options: [QueryOption]) -> Future<I> where I: Storable
    func insert<I>(condition: Bool, storable: I, options: [QueryOption]) -> Future<(I?, Bool)> where I: Storable
    
    func insert<I>(storables: [I], options: [QueryOption]) -> Future<[I]> where I: Storable
    func insert<I>(condition: Bool, storables: [I], options: [QueryOption]) -> Future<([I]?, Bool)> where I: Storable
    
    func find<I>(uuid: String, options: [QueryOption]) -> Future<I?> where I: Viewable
    func find<I>(condition: Bool, uuid: String, options: [QueryOption]) -> Future<(I?, Bool)> where I: Viewable
    
    func find<I>(uuids: [String], sorts: [Sort], limit: Int, offset: Int, options: [QueryOption]) -> Future<[I]> where I: Viewable
    func find<I>(condition: Bool, uuids: [String], sorts: [Sort], limit: Int, offset: Int, options: [QueryOption]) -> Future<([I]?, Bool)> where I: Viewable
    
    func fetch<I>(options: [QueryOption]) -> Future<[I]> where I: Viewable
    func fetch<I>(condition: Bool, options: [QueryOption]) -> Future<([I]?, Bool)> where I: Viewable
    
    func fetch<I>(query: Query?, options: [QueryOption]) -> Future<[I]> where I: Viewable
    func fetch<I>(condition: Bool, query: Query?, options: [QueryOption]) -> Future<([I]?, Bool)> where I: Viewable
    
    func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption]) -> Future<[I]> where I: Viewable
    func fetch<I>(condition: Bool, query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption]) -> Future<([I]?, Bool)> where I: Viewable
    
    func update<I>(storable: I, options: [QueryOption]) -> Future<I> where I: Storable
    func update<I>(condition: Bool, storable: I, options: [QueryOption]) -> Future<(I?, Bool)> where I: Storable
    
    func update<I>(storables: [I], options: [QueryOption]) -> Future<[I]> where I: Storable
    func update<I>(condition: Bool, storables: [I], options: [QueryOption]) -> Future<([I]?, Bool)> where I: Storable
    
    func delete<I>(uuid: String, type: I.Type, options: [QueryOption]) -> Future<Bool> where I: Storable
    func delete<I>(condition: Bool, uuid: String, type: I.Type, options: [QueryOption]) -> Future<(Bool?, Bool)> where I: Storable
    
    func delete<I>(uuids: [String], type: I.Type, options: [QueryOption]) -> Future<Bool> where I: Storable
    func delete<I>(condition: Bool, uuids: [String], type: I.Type, options: [QueryOption]) -> Future<(Bool?, Bool)> where I: Storable
    
    func count<T>(table: T, options: [QueryOption]) -> Future<Int> where T: Table
    func count<T>(condition: Bool, table: T, options: [QueryOption]) -> Future<(Int?, Bool)> where T: Table
    
    func count<T>(table: T, query: Query?, options: [QueryOption]) -> Future<Int> where T: Table
    func count<T>(condition: Bool, table: T, query: Query?, options: [QueryOption]) -> Future<(Int?, Bool)> where T: Table
    
}

extension Adapter {
    
    public func connect(condition: Bool) -> Future<(Bool?, Bool)> {
        if condition {
            return connect().then({ (success) -> Future<(Bool?, Bool)> in
                Future((success, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func disconnect(condition: Bool) -> Future<(Bool?, Bool)> {
        if condition {
            return disconnect().then({ (success) -> Future<(Bool?, Bool)> in
                Future((success, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func insert<I>(condition: Bool, storable: I, options: [QueryOption] = []) -> Future<(I?, Bool)> where I: Storable {
        if condition {
            return insert(storable: storable, options: options).then({ (storable) -> Future<(I?, Bool)> in
                Future((storable, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func insert<I>(condition: Bool, storables: [I], options: [QueryOption] = []) -> Future<([I]?, Bool)> where I: Storable {
        if condition {
            return insert(storables: storables, options: options).then({ (storables) -> Future<([I]?, Bool)> in
                Future((storables, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func find<I>(condition: Bool, uuid: String, options: [QueryOption] = []) -> Future<(I?, Bool)> where I: Viewable {
        if condition {
            return find(uuid: uuid, options: options).then({ (storable) -> Future<(I?, Bool)> in
                Future((storable, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func find<I>(condition: Bool, uuids: [String], sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, options: [QueryOption] = []) -> Future<([I]?, Bool)> where I: Viewable {
        if condition {
            return find(uuids: uuids, sorts: sorts, limit: limit, offset: offset, options: options).then({ (storables) -> Future<([I]?, Bool)> in
                Future((storables, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func fetch<I>(condition: Bool, options: [QueryOption] = []) -> Future<([I]?, Bool)> where I: Viewable {
        if condition {
            return fetch(options: options).then({ (storables) -> Future<([I]?, Bool)> in
                Future((storables, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func fetch<I>(condition: Bool, query: Query?, options: [QueryOption] = []) -> Future<([I]?, Bool)> where I: Viewable {
        if condition {
            return fetch(query: query, options: options).then({ (storables) -> Future<([I]?, Bool)> in
                Future((storables, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func fetch<I>(condition: Bool, query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0, options: [QueryOption] = []) -> Future<([I]?, Bool)> where I: Viewable {
        if condition {
            return fetch(query: query, sorts: sorts, limit: limit, offset: offset, options: options).then({ (storables) -> Future<([I]?, Bool)> in
                Future((storables, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func update<I>(condition: Bool, storable: I, options: [QueryOption] = []) -> Future<(I?, Bool)> where I: Storable {
        if condition {
            return update(storable: storable, options: options).then({ (storable) -> Future<(I?, Bool)> in
                Future((storable, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func update<I>(condition: Bool, storables: [I], options: [QueryOption] = []) -> Future<([I]?, Bool)> where I: Storable {
        if condition {
            return update(storables: storables, options: options).then({ (storables) -> Future<([I]?, Bool)> in
                Future((storables, true))
            })
        } else {
            return Future((nil, false))
        }
    }
    
    public func delete<I>(condition: Bool, uuid: String, type: I.Type, options: [QueryOption] = []) -> Future<(Bool?, Bool)> where I: Storable {
        if condition {
            return delete(uuid: uuid, type: type, options: options).then { (success) -> Future<(Bool?, Bool)> in
                Future((success, true))
            }
        } else {
            return Future((nil, false))
        }
    }
    
    public func delete<I>(condition: Bool, uuids: [String], type: I.Type, options: [QueryOption] = []) -> Future<(Bool?, Bool)> where I: Storable {
        if condition {
            return delete(uuids: uuids, type: type, options: options).then { (success) -> Future<(Bool?, Bool)> in
                Future((success, true))
            }
        } else {
            return Future((nil, false))
        }
    }
    
    public func count<T>(condition: Bool, table: T, options: [QueryOption] = []) -> Future<(Int?, Bool)> where T: Table {
        if condition {
            return count(table: table, options: options).then { (count) -> Future<(Int?, Bool)> in
                Future((count, true))
            }
        } else {
            return Future((nil, false))
        }
    }
    
    public func count<T>(condition: Bool, table: T, query: Query?, options: [QueryOption] = []) -> Future<(Int?, Bool)> where T: Table {
        if condition {
            return count(table: table, query: query, options: options).then { (count) -> Future<(Int?, Bool)> in
                Future((count, true))
            }
        } else {
            return Future((nil, false))
        }
    }
    
    public func fetch<I>(options: [QueryOption] = []) -> Future<[I]> where I: Viewable {
        return self.fetch(query: nil, options: options)
    }
    
    public func fetch<I>(query: Query?, options: [QueryOption] = []) -> Future<[I]> where I: Viewable {
        return self.fetch(query: query, sorts: [], limit: 0, offset: 0, options: options)
    }
    
    public func count<T>(table: T, options: [QueryOption] = []) -> Future<Int> where T: Table {
        return self.count(table: table, query: nil, options: options)
    }
    
}
