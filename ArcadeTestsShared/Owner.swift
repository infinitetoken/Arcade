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
    
    var uuid: String = UUID().uuidString
    var name: String?
    
}

extension Owner {
    
    enum CodingKeys: CodingKey {
        case uuid
        case name
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encodeIfPresent(name, forKey: .name)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
    }
    
}

extension Owner {
    
    var pets: Children<Owner, Pet> {
        return Children<Owner, Pet>(uuid: self.uuid)
    }
    
}
