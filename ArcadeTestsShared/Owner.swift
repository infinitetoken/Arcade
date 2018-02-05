//
//  Owner.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/4/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import Arcade

struct Owner: Storable {
    
    static var table: Table = TestTable.owner
    static var adapter: Adapter? {
        return TestTable.adapter
    }
    
    var uuid: UUID = UUID()
    var name: String?
    
    var dictionary: [String : Any]  {
        return [
            "uuid": self.uuid,
            "name": self.name ?? NSNull()
        ]
    }
    
}

extension Owner {
    
    var pets: Children<Owner, Pet> {
        return Children<Owner, Pet>(uuid: self.uuid, foreignKey: "ownerID")
    }
    
}
