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
    
}

extension Toy {
    
    enum CodingKeys: CodingKey {
        case uuid
        case name
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid.uuidString.lowercased(), forKey: .uuid)
        try container.encodeIfPresent(name, forKey: .name)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.uuid = try container.decode(UUID.self, forKey: .uuid)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
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
