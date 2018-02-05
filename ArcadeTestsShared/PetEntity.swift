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
    
    @NSManaged var uuid: UUID
    @NSManaged var name: String?
    
    @NSManaged var owner: OwnerEntity?
    @NSManaged var petToys: Set<PetToyEntity>
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.uuid = UUID()
    }
    
}

extension PetEntity: CoreDataStorable {
    
    public var storable: Storable {
        return Pet(uuid: self.uuid, name: self.name, ownerID: self.owner?.uuid)
    }
    
    public func update(withStorable dictionary: [String : Any]) -> Bool {
        if let uuid = dictionary["uuid"] as? UUID {
            self.uuid = uuid
        }
        if let name = dictionary["name"] as? String {
            self.name = name
        } else if dictionary["name"] is NSNull {
            self.name = nil
        }
        if let owner = dictionary["ownerID"] as? UUID, let managedObjectContext = self.managedObjectContext {
            self.owner = OwnerEntity.object(with: owner, entityName: "OwnerEntity", in: managedObjectContext) as? OwnerEntity
        } else if dictionary["ownerID"] is NSNull {
            self.owner = nil
        }
        
        return true
    }
    
}
