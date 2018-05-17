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
    
}

extension Pet {
    
    enum CodingKeys: CodingKey {
        case uuid
        case name
        case ownerID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid.uuidString.lowercased(), forKey: .uuid)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(ownerID?.uuidString.lowercased(), forKey: .ownerID)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.uuid = try container.decode(UUID.self, forKey: .uuid)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.ownerID = try container.decodeIfPresent(UUID.self, forKey: .ownerID)
    }
    
}

extension Pet {
    
    var owner: Parent<Pet, Owner> {
        return Parent<Pet, Owner>(uuid: self.ownerID)
    }
    
    var petToys: Children<Pet, PetToy> {
        return Children<Pet, PetToy>(uuid: self.uuid)
    }
    
    var toys: Siblings<Pet, Toy, PetToy> {
        return Siblings<Pet, Toy, PetToy>(uuid: self.uuid)
    }
    
}
