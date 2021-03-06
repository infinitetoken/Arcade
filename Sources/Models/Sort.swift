//
//  Sort.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct Sort {
    
    public enum Order: Int {
        case ascending = 1
        case descending = -1
    }
    
    public var key: String
    public var order: Order
    
    public init(key: String, order: Order) {
        self.key = key
        self.order = order
    }
    
}

public extension Sort {
 
    var dictionary: [String : Int] {
        return [self.key : self.order.rawValue]
    }
    
}

public extension Sort {
    
    func sortDescriptor() -> NSSortDescriptor {
        switch self.order {
        case .ascending:
            return NSSortDescriptor(key: self.key, ascending: true)
        case .descending:
            return NSSortDescriptor(key: self.key, ascending: false)
        }
    }
    
}

public extension Sort {
    
    func sort(viewables: [Viewable]) -> [Viewable] {
        let dicts = viewables.map { (viewable) -> [String : Any] in
            return viewable.dictionary
        }
        
        let sorted = zip(dicts, viewables).sorted { (a, b) -> Bool in
            switch self.sortDescriptor().compare(a.0, to: b.0) {
            case .orderedAscending:
                return true
            case .orderedDescending:
                return false
            case .orderedSame:
                return true
            }
        }
        
        return sorted.map { $0.1 }
    }
    
}
