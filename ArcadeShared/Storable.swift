//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public protocol Storable: Codable {
    
    var uuid: UUID { get set }
    var dictionary: [String: Any] { get }
    
}

extension Storable {
    
    public func query(query: Query) -> Bool { return query.predicate().evaluate(with: self.dictionary) }
    
}

