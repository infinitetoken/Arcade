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
    case updateFailed
    case notConnected
    case noResult
    case error(error: Error)
}

open class CoreDataAdapter {
    
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
    
    open func connect() -> Future<Bool> {
        return Future { completion in
            if let _ = self.persistentContainer {
                completion(.success(true))
                return
            }
            
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
                self.persistentContainer?.persistentStoreDescriptions = self.persistentStoreDescriptions
            }
            
            self.persistentContainer?.loadPersistentStores { (desc: NSPersistentStoreDescription, error: Error?) in
                if let error = error {
                    completion(.failure(CoreDataAdapterError.error(error: error)))
                } else {
                    completion(.success(true))
                }
            }
        }
    }
    
    open func disconnect() -> Future<Bool> {
        return Future(true)
    }
    
    public func insert<I>(storable: I) -> Future<Bool> where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext
            else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext)
            else { return Future(CoreDataAdapterError.entityNotFound) }
        guard let object = NSManagedObject(entity: entity, insertInto: managedObjectContext) as? CoreDataStorable
            else { return Future(CoreDataAdapterError.entityNotStorable) }
        guard object.update(withStorable: storable.dictionary) else { return Future(CoreDataAdapterError.updateFailed) }
        return Future(self.save())
    }
    
    public func insert<I>(storables: [I]) -> Future<Bool> where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext
            else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext)
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        guard let error: CoreDataAdapterError = storables.reduce(nil, {
            guard $0 == nil else { return $0 }
            guard let object = NSManagedObject(entity: entity, insertInto: managedObjectContext) as? CoreDataStorable
                else { return CoreDataAdapterError.entityNotStorable }
            guard object.update(withStorable: $1.dictionary) else { return CoreDataAdapterError.updateFailed }
            return nil
        }) else { return Future(self.save()) }
        
        managedObjectContext.undo()
        return Future(error)
    }
    
    public func find<I>(uuid: UUID) -> Future<I?> where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let expression = Expression.equal("uuid", uuid)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = expression.predicate()
        
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
    
    public func find<I>(uuids: [UUID], sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> Future<[I]> where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = limit
        fetchRequest.fetchOffset = offset
        fetchRequest.sortDescriptors = sorts.map({ (sort) -> NSSortDescriptor in
            return sort.sortDescriptor()
        })
        fetchRequest.predicate = Expression.comparison("uuid", Comparison.inside, uuids, []).predicate()
        
        return Future { operation in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
                guard let results = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                    operation(.failure(CoreDataAdapterError.noResult))
                    return
                }
                
                DispatchQueue.main.async { operation(.success(results.map { $0.storable } as! [I])) }
            }
            
            do {
                try managedObjectContext.execute(asynchronousFetchRequest)
            } catch {
                operation(.failure(CoreDataAdapterError.error(error: error)))
            }
        }
    }
    
    public func fetch<I>(query: Query?, sorts: [Sort] = [], limit: Int = 0, offset: Int = 0) -> Future<[I]> where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = query?.predicate()
        fetchRequest.sortDescriptors = sorts.map({ (sort) -> NSSortDescriptor in
            return sort.sortDescriptor()
        })
        fetchRequest.fetchLimit = limit
        fetchRequest.fetchOffset = offset
        
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
    
    public func update<I>(storable: I) -> Future<Bool> where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let expression = Expression.equal("uuid", storable.uuid)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = expression.predicate()
        
        return Future { operation in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
                guard let result = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                    operation(.failure(CoreDataAdapterError.noResult))
                    return
                }
                
                DispatchQueue.main.async {
                    if let object = result.first {
                        object.update(withStorable: storable.dictionary) ? operation(self.save()) : operation(.failure(CoreDataAdapterError.updateFailed))
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
    
    public func update<I>(storables: [I]) -> Future<Bool> where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let expression = Expression.comparison("uuid", Comparison.inside, storables.map{ $0.uuid }, [])
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = storables.count
        fetchRequest.predicate = expression.predicate()
        
        return Future { operation in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
                guard let results = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                    operation(.failure(CoreDataAdapterError.noResult))
                    return
                }
                DispatchQueue.main.async {
                    if let error = results.reduce(nil, { (error, coreDataStorable) -> CoreDataAdapterError? in
                        guard error == nil else { return error }
                        guard let dictionary: Dictionary<String, Any> = storables.reduce(nil, {
                            guard $0 == nil else { return $0 }
                            guard coreDataStorable.storable.uuid == $1.uuid else { return nil }
                            return $1.dictionary
                        }), coreDataStorable.update(withStorable: dictionary)
                            else { return CoreDataAdapterError.updateFailed }
                        return nil
                    }) {
                        managedObjectContext.undo()
                        operation(.failure(error))
                    } else {
                        operation(self.save())
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
    
    public func delete<I>(uuid: UUID, type: I.Type) -> Future<Bool> where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let expression = Expression.equal("uuid", uuid)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = expression.predicate()
        
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
    
    public func delete<I>(uuids: [UUID], type: I.Type) -> Future<Bool> where I : Storable {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return Future(CoreDataAdapterError.notConnected) }
        guard let entity = NSEntityDescription.entity(forEntityName: I.table.name, in: managedObjectContext),
            let entityName = entity.name
            else { return Future(CoreDataAdapterError.entityNotFound) }
        
        let expression = Expression.comparison("uuid", Comparison.inside, uuids, [])
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.fetchLimit = uuids.count
        fetchRequest.predicate = expression.predicate()
        
        return Future { operation in
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
                guard let results = asynchronousFetchResult.finalResult as? [CoreDataStorable] else {
                    operation(.failure(CoreDataAdapterError.noResult))
                    return
                }
                
                DispatchQueue.main.async {
                    guard results.count == uuids.count else {
                        operation(.failure(CoreDataAdapterError.entityNotFound))
                        return
                    }
                    results.forEach { managedObjectContext.delete($0 as! NSManagedObject) }
                    operation(self.save())
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
    
    private func save() -> Result<Bool> {
        guard let managedObjectContext = self.persistentContainer?.viewContext else { return .failure(CoreDataAdapterError.notConnected) }
        
        do {
            try managedObjectContext.save()
        } catch {
            return .failure(CoreDataAdapterError.error(error: error))
        }
        
        return .success(true)
    }
    
}

