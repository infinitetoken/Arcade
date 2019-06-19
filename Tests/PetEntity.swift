//
//  PetEntity.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/4/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import CoreData
import Arcade

@objc(PetEntity)
class PetEntity: NSManagedObject {
    
    @NSManaged var id: String
    @NSManaged var name: String?
    
    @NSManaged var owner: OwnerEntity?
    @NSManaged var petToys: Set<PetToyEntity>
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.id = UUID().uuidString
    }
    
}

extension PetEntity: CoreDataStorable {
    
    public var viewable: Viewable {
        return Pet(id: self.id, name: self.name, ownerID: self.owner?.id)
    }
    
    public var storable: Storable {
        return Pet(id: self.id, name: self.name, ownerID: self.owner?.id)
    }
    
    public func update(with storable: Storable) -> Bool {
        guard let pet = storable as? Pet else { return false }
        
        self.id = pet.id
        self.name = pet.name
        
        if let owner = pet.ownerID, let managedObjectContext = self.managedObjectContext {
            self.owner = OwnerEntity.object(with: owner, entityName: "OwnerEntity", in: managedObjectContext) as? OwnerEntity
        } else {
            self.owner = nil
        }
        
        return true
    }
    
}
