//
//  CoreDataAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import CoreData

public enum CoreDataAdapterError: Error {
    case parameterNotGiven
    case entityNotFound
    case entityNotStorable
    case noResult
    case error(error: Error)
}

public class CoreDataAdapter {
    
    public var persistentContainerName: String?
    public var persistentStoreDescriptions: [NSPersistentStoreDescription] = []
    public var managedObjectModel: NSManagedObjectModel?
    
    internal var persistentContainer: NSPersistentContainer!
    
    public convenience init(persistentContainerName: String, persistentStoreDescriptions: [NSPersistentStoreDescription] = [], managedObjectModel: NSManagedObjectModel? = nil) {
        self.init()
        
        self.persistentContainerName = persistentContainerName
        self.persistentStoreDescriptions = persistentStoreDescriptions
        self.managedObjectModel = managedObjectModel
    }
}

extension CoreDataAdapter: Adapter {
    
    public func connect() -> Future<Bool> {
        return Future { completion in
            guard let name = self.persistentContainerName else {
                completion(.failure(CoreDataAdapterError.parameterNotGiven))
                return
            }
            
            if let model = self.managedObjectModel {
                self.persistentContainer = NSPersistentContainer(name: name, managedObjectModel: model)
            } else {
                self.persistentContainer = NSPersistentContainer(name: name)
            }
            
            if self.persistentStoreDescriptions.count > 0 {
                self.persistentContainer.persistentStoreDescriptions = self.persistentStoreDescriptions
            }
            
            self.persistentContainer.loadPersistentStores { (desc: NSPersistentStoreDescription, error: Error?) in
                if let error = error {
                    completion(.failure(CoreDataAdapterError.error(error: error)))
                } else {
                    completion(.success(true))
                }
            }
        }
    }
    
    public func disconnect() -> Future<Bool> {
        return Future(true)
    }
    
    public func insert<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        let managedObjectContext = self.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: table.name, in: managedObjectContext) else { return Future(CoreDataAdapterError.entityNotFound) }
       
        guard let object = NSManagedObject(entity: entity, insertInto: managedObjectContext) as? CoreDataStorable else {
            return Future(CoreDataAdapterError.entityNotStorable)
        }
        
        return object.update(dictionary: storable.dictionary) ? Future(self.save()) : Future(false)
    }
    
    public func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I : Storable, T : Table {
        let managedObjectContext = self.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let predicate = NSPredicate(format: "uuid = %@", uuid as NSUUID)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = predicate
        
        return Future { operation in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
                guard let result = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                    operation(.failure(CoreDataAdapterError.noResult))
                    return
                }
                
                DispatchQueue.main.async {
                    let object = result.map({ (object) -> Storable in
                        return object.storable
                    }).first
        
                    operation(.success(object as! I?))
                }
            }
            
            do {
                try managedObjectContext.execute(asynchronousFetchRequest)
            } catch {
                operation(.failure(CoreDataAdapterError.error(error: error)))
            }
        }
    }
    
    public func fetch<I, T>(table: T, query: Query?) -> Future<[I]> where I : Storable, T : Table {
        let managedObjectContext = self.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = query?.predicate()
        
        return Future { operation in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
                guard let result = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                    operation(.failure(CoreDataAdapterError.noResult))
                    return
                }
                
                DispatchQueue.main.async {
                    let objects = result.map({ (object) -> Storable in
                        return object.storable
                    })
                    
                    operation(.success(objects as! [I]))
                }
            }
            
            do {
                try managedObjectContext.execute(asynchronousFetchRequest)
            } catch {
                operation(.failure(CoreDataAdapterError.error(error: error)))
            }
        }
    }
    
    public func update<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        let managedObjectContext = self.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let predicate = NSPredicate(format: "uuid = %@", storable.uuid as NSUUID)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = predicate
        
        return Future { operation in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
                guard let result = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                    operation(.failure(CoreDataAdapterError.noResult))
                    return
                }
                
                DispatchQueue.main.async {
                    if let object = result.first {
                        object.update(dictionary: storable.dictionary) ? operation(self.save()) : operation(.success(false))
                    } else {
                        operation(.success(false))
                    }
                }
            }
            
            do {
                try managedObjectContext.execute(asynchronousFetchRequest)
            } catch {
                operation(.failure(CoreDataAdapterError.error(error: error)))
            }
        }
    }
    
    public func delete<I, T>(table: T, storable: I) -> Future<Bool> where I : Storable, T : Table {
        let managedObjectContext = self.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let predicate = NSPredicate(format: "uuid = %@", storable.uuid as NSUUID)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = predicate
        
        return Future { operation in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
                guard let result = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                    operation(.failure(CoreDataAdapterError.noResult))
                    return
                }
                
                DispatchQueue.main.async {
                    if let object = result.first {
                        self.persistentContainer.viewContext.delete(object as! NSManagedObject)
                        operation(self.save())
                    } else {
                        operation(.success(false))
                    }
                }
            }
            
            do {
                try managedObjectContext.execute(asynchronousFetchRequest)
            } catch {
                operation(.failure(CoreDataAdapterError.error(error: error)))
            }
        }
    }
    
    public func count<T>(table: T, query: Query?) -> Future<Int> where T : Table {
        let managedObjectContext = self.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = query?.predicate()
        
        do {
            return Future(try self.persistentContainer.viewContext.count(for: fetchRequest))
        } catch {
            return Future(CoreDataAdapterError.error(error: error))
        }
    }
    
    private func save() -> Result<Bool> {
        let managedObjectContext = self.persistentContainer.viewContext
        
        do {
            try managedObjectContext.save()
        } catch {
            return .failure(CoreDataAdapterError.error(error: error))
        }
        
        return .success(true)
    }
}
