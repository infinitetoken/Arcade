//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public protocol Storable: Codable {
    
    static var table: Table { get }
    
    var uuid: UUID { get set }
    var dictionary: [String: Any] { get }
    var parents: [UUID] { get set }
    
}

extension Storable {
    
    var table: Table { return Self.table }
    
    public func query(query: Query) -> Bool { return query.predicate().evaluate(with: self.dictionary) }
    
}

