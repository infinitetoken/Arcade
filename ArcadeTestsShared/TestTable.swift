//
//  TestTable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 11/1/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import Arcade

enum TestTable: String, Table {
    case owner = "OwnerEntity"
    case pet = "PetEntity"
    case petToy = "PetToyEntity"
    case toy = "ToyEntity"
    case widget = "WidgetEntity"
    
    var name: String {
        return self.rawValue
    }
}
