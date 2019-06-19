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
    
    var id: String = UUID().uuidString
    
    var petID: String?
    var toyID: String?
    
}

extension PetToy {
    
    enum CodingKeys: CodingKey {
        case id
        case petID
        case toyID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(petID, forKey: .petID)
        try container.encodeIfPresent(toyID, forKey: .toyID)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.petID = try container.decodeIfPresent(String.self, forKey: .petID)
        self.toyID = try container.decodeIfPresent(String.self, forKey: .toyID)
    }
    
}
