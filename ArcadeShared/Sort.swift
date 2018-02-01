//
//  Sort.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct Sort {
    
    public enum Order {
        case ascending
        case descending
    }
    
    public var key: String
    public var order: Order
    
    public init(key: String, order: Order) {
        self.key = key
        self.order = order
    }
    
}

public extension Sort {
    
    public func sortDescriptor() -> NSSortDescriptor {
        switch self.order {
        case .ascending:
            return NSSortDescriptor(key: self.key, ascending: true)
        case .descending:
            return NSSortDescriptor(key: self.key, ascending: false)
        }
    }
    
}
