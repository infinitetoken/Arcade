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
    
    var name: String {
        return self.rawValue
    }
    
    var foreignKey: String {
        switch self {
        case .owner:
            return "ownerID"
        case .pet:
            return "petID"
        case .petToy:
            return "petToyID"
        case .toy:
            return "toyID"
        }
    }
    
    public static var adapter: Adapter? {
        return Arcade.shared.adapter(forKey: "Test")
    }
}
