//
//  DatabaseTable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public func !=(lhs: Table, rhs: Table) -> Bool { return lhs.name != rhs.name }
public func ==(lhs: Table, rhs: Table) -> Bool { return lhs.name == rhs.name }

public protocol Table {
    
    var name: String { get }
    var foreignKey: String { get }
    
}
