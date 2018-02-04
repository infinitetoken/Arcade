//
//  PetToy.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/4/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import Arcade

struct PetToy: Storable {
    
    static var table: Table = TestTable.petToy
    static var adapter: Adapter?
    
    var uuid: UUID
    
    var dictionary: [String : Any]  {
        return [
            "uuid": self.uuid
        ]
    }
    
}
