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
    static var adapter: Adapter?
    
    var uuid: UUID
    var name: String?
    
    var dictionary: [String : Any]  {
        return [
            "uuid": self.uuid,
            "name": self.name ?? NSNull()
        ]
    }
    
}
