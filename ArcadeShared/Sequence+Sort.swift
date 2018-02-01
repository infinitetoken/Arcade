//
//  Sequence+Sort.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public extension Sequence where Iterator.Element : Any {
    
    public func sorted(with sortDescriptors: [NSSortDescriptor]) -> [Self.Iterator.Element] {
        return sorted {
            for sortDescriptor in sortDescriptors {
                switch sortDescriptor.compare($0, to: $1) {
                case .orderedAscending: return true
                case .orderedDescending: return false
                case .orderedSame: continue
                }
            }
            return false
        }
    }
    
}
