//
//  Viewable.swift
//  Arcade
//
//  Created by Paul Foster on 3/7/19.
//  Copyright © 2019 A.C. Wright Design. All rights reserved.
//

import Foundation

public func !=(lhs: Viewable, rhs: Viewable) -> Bool { return lhs.uuid != rhs.uuid }
public func ==(lhs: Viewable, rhs: Viewable) -> Bool { return lhs.uuid == rhs.uuid }

public protocol Viewable: Codable {
    
    static var table: Table { get }
    
    var uuid: String { get set }
    
}

public extension Viewable {
    
    public var table: Table { return Self.table }
    
}

public extension Viewable {
    
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
