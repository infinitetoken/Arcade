//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import Future

public func !=(lhs: Storable, rhs: Storable) -> Bool { return lhs.uuid != rhs.uuid }
public func ==(lhs: Storable, rhs: Storable) -> Bool { return lhs.uuid == rhs.uuid }

public protocol Storable: Codable {
    
    static var table: Table { get }
    
    var uuid: String { get set }

}

public extension Storable {
    
    public var table: Table { return Self.table }
    
}

public extension Storable {
    
    public var dictionary: [String : Any] {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(self)
            
            guard let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else { return [:] }
            
            return result
        } catch {
            return [:]
        }
    }
    
}
