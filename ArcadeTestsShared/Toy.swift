//
//  Toy.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/4/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import Arcade

struct Toy: Storable {
    
    static var table: Table = TestTable.toy
    static var adapter: Adapter? {
        return TestTable.adapter
    }
    
    var uuid: UUID = UUID()
    var name: String?
    
    var dictionary: [String: Any] {
        return [
            "uuid": self.uuid,
            "name": self.name ?? NSNull()
        ]
    }
    
}

extension Toy {
    
    var petToys: Children<Toy, PetToy> {
        return Children<Toy, PetToy>(uuid: self.uuid)
    }
    
    var pets: Siblings<Toy, Pet, PetToy> {
        return Siblings<Toy, Pet, PetToy>(uuid: self.uuid)
    }
    
}
