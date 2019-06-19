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
    
    @NSManaged var id: String
    
    @NSManaged var pet: PetEntity?
    @NSManaged var toy: ToyEntity?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.id = UUID().uuidString
    }
    
}

extension PetToyEntity: CoreDataStorable {
    
    public var viewable: Viewable {
        return PetToy(id: self.id, petID: self.pet?.id, toyID: self.toy?.id)
    }
    
    public var storable: Storable {
        return PetToy(id: self.id, petID: self.pet?.id, toyID: self.toy?.id)
    }
    
    public func update(with storable: Storable) -> Bool {
        guard let petToy = storable as? PetToy else { return false }
        
        self.id = petToy.id
        
        if let pet = petToy.petID, let managedObjectContext = self.managedObjectContext {
            self.pet = PetEntity.object(with: pet, entityName: "PetEntity", in: managedObjectContext) as? PetEntity
        } else {
            self.pet = nil
        }
        if let toy = petToy.toyID, let managedObjectContext = self.managedObjectContext {
            self.toy = ToyEntity.object(with: toy, entityName: "ToyEntity", in: managedObjectContext) as? ToyEntity
        } else {
            self.toy = nil
        }
        
        return true
    }
    
}
