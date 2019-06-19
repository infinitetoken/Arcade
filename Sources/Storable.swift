//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public func !=(lhs: Storable, rhs: Storable) -> Bool { return lhs.id != rhs.id }
public func ==(lhs: Storable, rhs: Storable) -> Bool { return lhs.id == rhs.id }

public protocol Storable: Viewable {}
