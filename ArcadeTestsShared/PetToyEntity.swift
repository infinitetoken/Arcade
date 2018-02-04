//
//  PetToyEntity.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/4/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import CoreData
import Arcade

@objc(PetToyEntity)
class PetToyEntity: NSManagedObject {
    
    @NSManaged var uuid: UUID
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.uuid = UUID()
    }
    
}

extension PetToyEntity: CoreDataStorable {
    
    public var storable: Storable {
        return PetToy(uuid: self.uuid)
    }
    
    public func update(withStorable dictionary: [String : Any]) -> Bool {
        if let uuid = dictionary["uuid"] as? UUID {
            self.uuid = uuid
        }
        
        return true
    }
    
}
