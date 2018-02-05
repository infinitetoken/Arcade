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
    static var adapter: Adapter? {
        return TestTable.adapter
    }
    
    var uuid: UUID = UUID()
    
    var petID: UUID?
    var toyID: UUID?
    
    var dictionary: [String : Any]  {
        return [
            "uuid": self.uuid,
            "petID": self.petID ?? NSNull(),
            "toyID": self.toyID ?? NSNull()
        ]
    }
    
}

extension PetToy {
    
    var pet: Parent<PetToy, Pet> {
        return Parent<PetToy, Pet>(uuid: self.petID)
    }
    
    var toy: Parent<PetToy, Toy> {
        return Parent<PetToy, Toy>(uuid: self.toyID)
    }
    
}
