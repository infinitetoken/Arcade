//
//  WidgetEntity+CoreDataStorable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import CoreData
import Arcade

extension WidgetEntity: CoreDataStorable {
    
    public var storable: Storable {
        return Widget(uuid: self.uuid ?? UUID(), name: self.name)
    }
    
    public func update(fromStorable dictionary: [String : Any]) -> Bool {
        guard let uuid = dictionary["uuid"] as? String else { return false }
        guard let name = dictionary["name"] as? String else { return false }
        
        self.uuid = UUID(uuidString: uuid)
        self.name = name
        
        return true
    }
    
}
