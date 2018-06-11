//
//  OwnerEntity.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/4/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import CoreData
import Arcade

@objc(OwnerEntity)
class OwnerEntity: NSManagedObject {
    
    @NSManaged var uuid: String
    @NSManaged var name: String?
    
    @NSManaged var pets: Set<PetEntity>
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.uuid = UUID().uuidString
    }
    
}

extension OwnerEntity: CoreDataStorable {
    
    public var storable: Storable {
        return Owner(uuid: self.uuid, name: self.name)
    }
    
    public func update(with storable: Storable) -> Bool {
        guard let owner = storable as? Owner else { return false }
        
        self.uuid = owner.uuid
        self.name = owner.name
        
        return true
    }
    
}
