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
    
    var id: String = UUID().uuidString
    var name: String?
    
    var ownerID: String?
    
}

extension Pet {
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case ownerID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(ownerID, forKey: .ownerID)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.ownerID = try container.decodeIfPresent(String.self, forKey: .ownerID)
    }
    
}
