//
//  CoreDataAdapter.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation
import CoreData

open class CoreDataAdapter {
    
    public enum AdapterError: LocalizedError {
        case parameterNotGiven
        case entityNotFound
        case entityNotStorable
        case updateFailed
        case saveFailed
        case notConnected
        case noResult
        case error(error: Error)
        
        public var errorDescription: String? {
            switch self {
            case .parameterNotGiven:
                return "Parameter not given"
            case .entityNotFound:
                return "Entity not found"
            case .entityNotStorable:
                return "Entity not storable"
            case .updateFailed:
                return "Update failed"
            case .saveFailed:
                return "Save failed"
            case .notConnected:
                return "Not connected"
            case .noResult:
                return "No result"
            case .error(let error):
                return error.localizedDescription
            }
        }
    }
    
    open var persistentContainerName: String?
    open var persistentStoreDescriptions: [NSPersistentStoreDescription] = []
    open var managedObjectModel: NSManagedObjectModel?
    
    private var persistentContainer: NSPersistentContainer?
    
    public init() {}
    
    public convenience init(persistentContainerName: String?, persistentStoreDescriptions: [NSPersistentStoreDescription], managedObjectModel: NSManagedObjectModel?) {
        self.init()
        
        self.persistentContainerName = persistentContainerName
        self.persistentStoreDescriptions = persistentStoreDescriptions
        self.managedObjectModel = managedObjectModel
    }
    
}

extension CoreDataAdapter: Adapter {

    open func connect(completion: @escaping (Result<Bool, Error>) -> Void) {
        if let _ = self.persistentContainer {
            completion(.success(true))
        }
        
        guard let name = self.persistentContainerName else {
            completion(.failure(AdapterError.parameterNotGiven))
            return
        }
        
        if let model = self.managedObjectModel {
            self.persistentContainer = NSPersistentContainer(name: name, managedObjectModel: model)
        } else {
            self.persistentContainer = NSPersistentContainer(name: name)
        }
        
        if self.persistentStoreDescriptions.count > 0 {
            self.persistentContainer?.persistentStoreDescriptions = self.persistentStoreDescriptions
        }
        
        self.persistentContainer?.loadPersistentStores { (desc: NSPersistentStoreDescription, error: Error?) in
            if let error = error {
                completion(.failure(AdapterError.error(error: error)))
            } else {
                completion(.success(true))
            }
        }
    }
    
    open func disconnect(completion: @escaping (Result<Bool, Error>) -> Void) {
        return completion(.success(true))
    }
    
    public func insert<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext
            else { completion(.failure(AdapterError.notConnected)); return }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext)
            else { completion(.failure(AdapterError.entityNotFound)); return }
        guard let object = NSManagedObject(entity: entity, insertInto: managedObjectContext) as? CoreDataStorable
            else { completion(.failure(AdapterError.entityNotStorable)); return }
        guard object.update(with: storable) else { completion(.failure(AdapterError.updateFailed)); return }
        
        switch self.save() {
        case .success(_): completion(.success(storable))
        case .failure(_): completion(.failure(AdapterError.saveFailed))
        }
    }
    
    public func find<I>(uuid: String, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Viewable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { completion(.failure(AdapterError.notConnected)); return }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { completion(.failure(AdapterError.entityNotFound)); return }
        
        let expression = Expression.equal("uuid", uuid)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = expression.predicate()
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
            guard let result = asynchronousFetchResult.finalResult as? [CoreDataViewable] else {
                completion(.failure(AdapterError.noResult))
                return
            }
            
            DispatchQueue.main.async {
                if let object = result.map({ (object) -> Viewable in
                    return object.viewable
                }).first as? I {
                    completion(.success(object))
                } else {
                    completion(.failure(AdapterError.noResult))
                }
            }
        }
        
        do {
            try managedObjectContext.execute(asynchronousFetchRequest)
        } catch {
            completion(.failure(AdapterError.error(error: error)))
        }
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort], limit: Int, offset: Int, options: [QueryOption], completion: @escaping (Result<[I], Error>) -> Void) where I : Viewable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { completion(.failure(AdapterError.notConnected)); return }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { completion(.failure(AdapterError.entityNotFound)); return }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = query?.predicate()
        fetchRequest.sortDescriptors = sorts.map({ (sort) -> NSSortDescriptor in
            return sort.sortDescriptor()
        })
        fetchRequest.fetchLimit = limit
        fetchRequest.fetchOffset = offset
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
            guard let result = asynchronousFetchResult.finalResult as? [CoreDataViewable] else {
                completion(.failure(AdapterError.noResult))
                return
            }
            
            DispatchQueue.main.async {
                let objects = result.map({ (object) -> Viewable in
                    return object.viewable
                })
                
                completion(.success(objects as! [I]))
            }
        }
        
        do {
            try managedObjectContext.execute(asynchronousFetchRequest)
        } catch {
            completion(.failure(AdapterError.error(error: error)))
        }
    }
    
    public func update<I>(storable: I, options: [QueryOption], completion: @escaping (Result<I, Error>) -> Void) where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { completion(.failure(AdapterError.notConnected)); return }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { completion(.failure(AdapterError.entityNotFound)); return }
        
        let expression = Expression.equal("uuid", storable.uuid)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = expression.predicate()
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
            guard let result = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                completion(.failure(AdapterError.noResult))
                return
            }
            
            DispatchQueue.main.async {
                if let object = result.first {
                    if object.update(with: storable) {
                        switch self.save() {
                        case .success(_): completion(.success(storable))
                        case .failure(_): completion(.failure(AdapterError.updateFailed))
                        }
                    } else {
                        completion(.failure(AdapterError.updateFailed))
                    }
                } else {
                    completion(.failure(AdapterError.noResult))
                }
            }
        }
        
        do {
            try managedObjectContext.execute(asynchronousFetchRequest)
        } catch {
            completion(.failure(AdapterError.error(error: error)))
        }
    }
    
    public func delete<I>(uuid: String, type: I.Type, options: [QueryOption], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { completion(.failure(AdapterError.notConnected)); return }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { completion(.failure(AdapterError.entityNotFound)); return }
        
        let expression = Expression.equal("uuid", uuid)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = expression.predicate()
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
            guard let result = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                completion(.failure(AdapterError.noResult))
                return
            }
            
            DispatchQueue.main.async {
                if let object = result.first {
                    managedObjectContext.delete(object as! NSManagedObject)
                    completion(self.save())
                } else {
                    completion(.failure(AdapterError.noResult))
                }
            }
        }
        
        do {
            try managedObjectContext.execute(asynchronousFetchRequest)
        } catch {
            completion(.failure(AdapterError.error(error: error)))
        }
    }
    
    public func count<T>(table: T, query: Query?, options: [QueryOption], completion: @escaping (Result<Int, Error>) -> Void) where T : Table {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { completion(.failure(AdapterError.notConnected)); return }
        guard let entity = NSEntityDescription.entity(forEntityName: table.name, in: managedObjectContext),
            let entityName = entity.name
            else { completion(.failure(AdapterError.entityNotFound)); return }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = query?.predicate()
        
        do {
            return completion(.success(try managedObjectContext.count(for: fetchRequest)))
        } catch {
            return completion(.failure(AdapterError.error(error: error)))
        }
    }
    
    private func save() -> Result<Bool, Error> {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return .failure(AdapterError.notConnected) }
        
        do {
            try managedObjectContext.save()
        } catch {
            return .failure(AdapterError.error(error: error))
        }
        
        return .success(true)
    }
    
}

