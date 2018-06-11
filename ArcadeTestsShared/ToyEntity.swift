//
//  ToyEntity.swift
//  Arcade
//
//  Created by A.C. Wright Design on 2/4/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation
import CoreData
import Arcade

@objc(ToyEntity)
class ToyEntity: NSManagedObject {
    
    @NSManaged var uuid: String
    @NSManaged var name: String?
    
    @NSManaged var petToys: Set<PetToyEntity>
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.uuid = UUID().uuidString
    }
    
}

extension ToyEntity: CoreDataStorable {
    
    public var storable: Storable {
        return Toy(uuid: self.uuid, name: self.name)
    }
    
    public func update(with storable: Storable) -> Bool {
        guard let toy = storable as? Toy else { return false }
        
        self.uuid = toy.uuid
        self.name = toy.name
        
        return true
    }
    
}
