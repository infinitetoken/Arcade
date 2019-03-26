//
//  Sequence+Offset.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/1/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public extension Array {
    
    func offset(by offset: Int) -> [Array.Iterator.Element] {
        if offset > self.endIndex {
            return []
        } else if offset > 0 {
            return Array(self.suffix(from: Swift.min(offset, self.endIndex)))
        }
        return self
    }
    
}
