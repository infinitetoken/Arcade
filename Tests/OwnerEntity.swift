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
    
    @NSManaged var id: String
    @NSManaged var name: String?
    
    @NSManaged var pets: Set<PetEntity>
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.id = UUID().uuidString
    }
    
}

extension OwnerEntity: CoreDataStorable {
    
    public var viewable: Viewable {
        return Owner(id: self.id, name: self.name)
    }
    
    public var storable: Storable {
        return Owner(id: self.id, name: self.name)
    }
    
    public func update(with storable: Storable) -> Bool {
        guard let owner = storable as? Owner else { return false }
        
        self.id = owner.id
        self.name = owner.name
        
        return true
    }
    
}
