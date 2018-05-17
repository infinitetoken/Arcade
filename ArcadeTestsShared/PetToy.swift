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
    
}

extension PetToy {
    
    enum CodingKeys: CodingKey {
        case uuid
        case petID
        case toyID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid.uuidString.lowercased(), forKey: .uuid)
        try container.encodeIfPresent(petID?.uuidString.lowercased(), forKey: .petID)
        try container.encodeIfPresent(toyID?.uuidString.lowercased(), forKey: .toyID)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.uuid = try container.decode(UUID.self, forKey: .uuid)
        self.petID = try container.decodeIfPresent(UUID.self, forKey: .petID)
        self.toyID = try container.decodeIfPresent(UUID.self, forKey: .toyID)
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
