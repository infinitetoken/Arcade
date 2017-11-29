//
//  NSComparison+Description.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/28/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

extension NSComparisonPredicate.Options: CustomStringConvertible {
 
    public var description: String {
        var description = ""
        
        if self.contains(.caseInsensitive) {
            description += "c"
        }
        if self.contains(.diacriticInsensitive) {
            description += "d"
        }
        if self.contains(.normalized) {
            description += "n"
        }
        
        return description
    }
    
}
