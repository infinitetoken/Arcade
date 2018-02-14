//
//  Parents.swift
//  Arcade
//
//  Created by Paul Foster on 2/10/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public struct Parents<C,P> where C: Storable, P: Storable {
    
    let uuids: [UUID]
    
    
    init(_ uuids: [UUID]) {
        self.uuids = uuids
    }
    
    
    
    
}
