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
    
    @NSManaged var uuid: UUID
    @NSManaged var name: String?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.uuid = UUID()
    }
    
}

extension OwnerEntity: CoreDataStorable {
    
    public var storable: Storable {
        return Owner(uuid: self.uuid, name: self.name)
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
        
        return true
    }
    
}
