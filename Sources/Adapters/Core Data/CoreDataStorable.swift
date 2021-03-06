//
//  CoreDataStorable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public protocol CoreDataStorable: CoreDataViewable {
    
    var storable: Storable { get }
        
    func update(with storable: Storable) -> Bool
    
}
