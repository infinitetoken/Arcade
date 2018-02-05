//
//  NSManagedObject+Find.swift
//  Arcade
//
//  Created by Aaron Wright on 2/5/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import XCTest
import CoreData

extension NSManagedObject {
    
    public class func object(with uuid: UUID, entityName: String, in managedObjectContext: NSManagedObjectContext) -> NSManagedObject? {
        let leftExpression = NSExpression(forKeyPath: "uuid")
        let rightExpression = NSExpression(forConstantValue: uuid)
        let modifier = NSComparisonPredicate.Modifier.direct
        let type = NSComparisonPredicate.Operator.equalTo
        let filterPredicate = NSComparisonPredicate(leftExpression: leftExpression, rightExpression: rightExpression, modifier: modifier, type: type, options: [])
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = filterPredicate
        fetchRequest.fetchLimit = 1
        
        var objects: [NSManagedObject] = []
        
        managedObjectContext.performAndWait {
            do {
                objects = try fetchRequest.execute()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        return objects.first
    }
    
}
