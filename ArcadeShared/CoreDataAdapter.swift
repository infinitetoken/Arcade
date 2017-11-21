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
    case notConnected
    case noResult
    case error(error: Error)
}

public struct CoreDataAdapter {
    
    public let persistentContainerName: String?
    public let persistentStoreDescriptions: [NSPersistentStoreDescription]
    public let managedObjectModel: NSManagedObjectModel?
    
    internal let persistentContainer: NSPersistentContainer?
    
    public init(persistentContainerName: String?, persistentStoreDescriptions: [NSPersistentStoreDescription], managedObjectModel: NSManagedObjectModel?, persistentContainer: NSPersistentContainer? = nil) {
        self.persistentContainerName = persistentContainerName
        self.persistentStoreDescriptions = persistentStoreDescriptions
        self.managedObjectModel = managedObjectModel
        self.persistentContainer = persistentContainer
    }
}

extension CoreDataAdapter: Adapter {
    
    public func connect() -> Future<CoreDataAdapter> {
        
        return Future { completion in
            guard let name = self.persistentContainerName else {
                completion(.failure(CoreDataAdapterError.parameterNotGiven))
                return
            }
            
            var persistentContainer: NSPersistentContainer?
            
            if let model = self.managedObjectModel {
                persistentContainer = NSPersistentContainer(name: name, managedObjectModel: model)
            } else {
                persistentContainer = NSPersistentContainer(name: name)
            }
            
            if self.persistentStoreDescriptions.count > 0 {
                persistentContainer?.persistentStoreDescriptions = self.persistentStoreDescriptions
            }
            
            persistentContainer?.loadPersistentStores { (desc: NSPersistentStoreDescription, error: Error?) in
                if let error = error {
                    completion(.failure(CoreDataAdapterError.error(error: error)))
                } else {
                    completion(.success(CoreDataAdapter(persistentContainerName: name, persistentStoreDescriptions: self.persistentStoreDescriptions, managedObjectModel: self.managedObjectModel, persistentContainer: persistentContainer)))
                }
            }
        }
    }
    
    public func disconnect() -> Future<CoreDataAdapter> {
        return Future(self)
    }
    
    public func insert<I, T>(table: T, storable: I) -> Future<CoreDataAdapter> where I : Storable, T : Table {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: table.name, in: managedObjectContext) else { return Future(CoreDataAdapterError.entityNotFound) }
        guard let object = NSManagedObject(entity: entity, insertInto: managedObjectContext) as? CoreDataStorable else {
            return Future(CoreDataAdapterError.entityNotStorable)
        }
        guard object.update(dictionary: storable.dictionary) else { return Future(CoreDataAdapterError.noResult) }
        
        return Future(self.save())
    }
    
    public func find<I, T>(table: T, uuid: UUID) -> Future<I?> where I : Storable, T : Table {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
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
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
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
    
    public func update<I, T>(table: T, storable: I) -> Future<CoreDataAdapter> where I : Storable, T : Table {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
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
                        object.update(dictionary: storable.dictionary) ? operation(self.save()) : operation(.failure(CoreDataAdapterError.noResult))
                    } else {
                        operation(.failure(CoreDataAdapterError.noResult))
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
    
    public func delete<I, T>(table: T, uuid: UUID, type: I.Type) -> Future<CoreDataAdapter> where I : Storable, T : Table {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
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
                    if let object = result.first {
                        managedObjectContext.delete(object as! NSManagedObject)
                        operation(self.save())
                    } else {
                        operation(.failure(CoreDataAdapterError.noResult))
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
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = query?.predicate()
        
        do {
            return Future(try managedObjectContext.count(for: fetchRequest))
        } catch {
            return Future(CoreDataAdapterError.error(error: error))
        }
    }
    
    private func save() -> Result<CoreDataAdapter> {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return .failure(CoreDataAdapterError.notConnected) }
        
        do {
            try managedObjectContext.save()
        } catch {
            return .failure(CoreDataAdapterError.error(error: error))
        }
        
        return .success(self)
    }
}

