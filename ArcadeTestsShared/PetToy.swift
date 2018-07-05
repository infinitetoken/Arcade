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
    
    var uuid: String = UUID().uuidString
    
    var petID: String?
    var toyID: String?
    
}

extension PetToy {
    
    enum CodingKeys: CodingKey {
        case uuid
        case petID
        case toyID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encodeIfPresent(petID, forKey: .petID)
        try container.encodeIfPresent(toyID, forKey: .toyID)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.petID = try container.decodeIfPresent(String.self, forKey: .petID)
        self.toyID = try container.decodeIfPresent(String.self, forKey: .toyID)
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
