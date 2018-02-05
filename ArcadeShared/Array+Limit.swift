//
//  Array+Limit.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public extension Array {
    
    public func limit(to limit: Int) -> [Array.Iterator.Element] {
        if limit > 0 {
            return Array(self.prefix(upTo: Swift.min(limit, self.count)))
        }
        return self
    }
    
}
