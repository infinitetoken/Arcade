//
//  Widget.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import Arcade

struct Widget: Storable {
    
    
    static var table: Table = WidgetTable.widget
    
    
    var uuid: UUID
    var name: String?
    
    var dictionary: [String : Any]  {
        return [
            "uuid": self.uuid,
            "name": self.name ?? NSNull()
        ]
    }
    
}
