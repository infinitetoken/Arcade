//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

enum StorableError: Error {
    case noParentUUID
}

public protocol Storable: Codable {
    
    static var table: Table { get }
    static var adapter: Adapter { get }
    
    var uuid: UUID { get set }
    var dictionary: [String: Any] { get }
    var parents: Dictionary<String, UUID> { get }
        
}

extension Storable {
    
    public var table: Table { return Self.table }
    
    public func query(query: Query) -> Bool { return query.predicate().evaluate(with: self.dictionary) }
    
}
