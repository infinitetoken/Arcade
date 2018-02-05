//
//  Pet.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/4/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import Arcade

struct Pet: Storable {
    
    static var table: Table = TestTable.pet
    static var adapter: Adapter? {
        return TestTable.adapter
    }
    
    var uuid: UUID = UUID()
    var name: String?
    
    var ownerID: UUID?
    
    var dictionary: [String : Any]  {
        return [
            "uuid": self.uuid,
            "name": self.name ?? NSNull(),
            "ownerID": self.ownerID ?? NSNull()
        ]
    }
    
}

extension Pet {
    
    var owner: Parent<Pet, Owner> {
        return Parent<Pet, Owner>(uuid: self.ownerID)
    }
    
    var petToys: Children<Pet, PetToy> {
        return Children<Pet, PetToy>(uuid: self.uuid, foreignKey: "petID")
    }
    
    var toys: Siblings<Pet, Toy, PetToy> {
        return Siblings<Pet, Toy, PetToy>(uuid: self.uuid, originForeignKey: "petID", destinationForeignKey: "toyID", destinationIDKey: "uuid")
    }
    
}
