//
//  JSCoreData.swift
//  JSCoreData
//
//  Created by Jonathan Sack on 6/15/22.
//

import CoreData

final public class JSCoreData {
    
    // MARK: - Init
    public init(persistentContainer: String, mergePolicy: NSMergePolicy = .mergeByPropertyObjectTrump) {
        let container = NSPersistentContainer(name: persistentContainer)
        container.loadPersistentStores(completionHandler: { (storeDescrip, error) in
            if let error { fatalError(error.localizedDescription) }
        })
        self.persistentContainer = container
        self.mergePolicy = mergePolicy
    }
    
    // MARK: - Properties
    private let persistentContainer: NSPersistentContainer
    private let mergePolicy: NSMergePolicy

    // MARK: - Contexts
    // View context
    private lazy var viewContext: NSManagedObjectContext = {
        let context = persistentContainer.viewContext
        context.mergePolicy = mergePolicy
        return context
    }()
    
    // Background context
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = mergePolicy
        return context
    }()

    // MARK: - Get
    // Get
    public func getObjects<T: JSCoreDataCodable>(matching predicate: NSPredicate? = nil) throws -> [T] {
        return try getObjects(matching: predicate, inContext: viewContext)
    }
    
    // Get in background
    public func getObjectsInBackground<T: JSCoreDataCodable>(matching predicate: NSPredicate? = nil) async throws -> [T] {
        try await backgroundContext.perform { [weak self] in
            guard let self else { return [] }
            return try self.getObjects(matching: predicate, inContext: self.backgroundContext)
        }
    }

    // MARK: - Save
    // Save object
    public func setObject<T: JSCoreDataCodable>(_ object: T) throws {
        try setObject(object, inContext: viewContext)
    }

    // Save objects
    public func setObjects<T: JSCoreDataCodable>(_ objects: [T]) throws {
        for object in objects {
            try setObject(object)
        }
    }

    // Save object in background
    public func setObjectInBackground<T: JSCoreDataCodable>(_ object: T) async throws {
        try await backgroundContext.perform { [weak self] in
            guard let self else { return }
            try self.setObject(object, inContext: self.backgroundContext)
        }
    }

    // Save objects in background
    public func setObjectsInBackground<T: JSCoreDataCodable>(_ objects: [T]) async throws {
        for object in objects {
            try await setObjectInBackground(object)
        }
    }

    // MARK: - Update
    // Update
    public func updateObjects<T: JSCoreDataCodable>(
        matching predicate: NSPredicate? = nil,
        updateBlock: ([T.CoreDataModel]) -> ()
    ) throws -> [T] {
        try updateObjects(matching: predicate, updateBlock: updateBlock, inContext: viewContext)
    }
    
    // Update in background
    public func updateObjectsInBackground<T: JSCoreDataCodable>(
        matching predicate: NSPredicate? = nil,
        updateBlock: @escaping ([T.CoreDataModel]) -> ()
    ) async throws -> [T] {
        try await backgroundContext.perform { [weak self] in
            guard let self else { return [] }
            return try self.updateObjects(
                matching: predicate,
                updateBlock: updateBlock,
                inContext: self.backgroundContext
            )
        }
    }
    
    // MARK: - Delete
    // Delete
    @discardableResult
    public func deleteObjects<T: JSCoreDataCodable>(matching predicate: NSPredicate? = nil) throws -> [T] {
        return try deleteObjects(matching: predicate, inContext: viewContext)
    }
    
    // Delete in background
    @discardableResult
    public func deleteObjectsInBackground<T: JSCoreDataCodable>(
        matching predicate: NSPredicate? = nil
    ) async throws -> [T] {
        try await backgroundContext.perform { [weak self] in
            guard let self else { return [] }
            return try self.deleteObjects(matching: predicate, inContext: self.backgroundContext)
        }
    }
}

// MARK: - EXT. Error
public enum JSCoreDataError: Error {
    case unknownEntity
}

// MARK: - EXT. Helper Methods
private extension JSCoreData {
    // Get
    func getObjects<T: JSCoreDataCodable>(matching predicate: NSPredicate? = nil, inContext context: NSManagedObjectContext) throws -> [T] {
        // Set fetch request
        let fetchRequest = NSFetchRequest<T.CoreDataModel>(entityName: T.entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = T.CoreDataModel.sortDescriptors
        
        return try context
            .fetch(fetchRequest)
            .compactMap { T(coreDataModel: $0) }
    }
    
    // Save
    func setObject<T: JSCoreDataCodable>(_ object: T, inContext context: NSManagedObjectContext) throws {
        // Create a new Entity
        guard let entity = NSEntityDescription.entity(forEntityName: T.entityName, in: context) else {
            throw JSCoreDataError.unknownEntity
        }

        // Set CoreData model in managed object context
        object.insertCoreDataModel(entity: entity, inContext: context)

        // Save context
        try context.save()
    }
    
    // Update objects
    func updateObjects<T: JSCoreDataCodable>(
        matching predicate: NSPredicate? = nil,
        updateBlock: ([T.CoreDataModel]) -> (),
        inContext context: NSManagedObjectContext
    ) throws -> [T] {
        // Fetch matching CoreData objects
        let fetchRequest = NSFetchRequest<T.CoreDataModel>(entityName: T.entityName)
        fetchRequest.predicate = predicate
        let items = try context.fetch(fetchRequest)
        let oldCopies = items.compactMap { T(coreDataModel: $0) }
        
        // Update objects
        updateBlock(items)
        try context.save()
        
        // Return old copies of updated items
        return oldCopies
    }

    // Delete objects
    func deleteObjects<T: JSCoreDataCodable>(
        matching predicate: NSPredicate? = nil,
        inContext context: NSManagedObjectContext
    ) throws -> [T] {
        // Fetch matching CoreData objects
        let fetchRequest = NSFetchRequest<T.CoreDataModel>(entityName: T.entityName)
        fetchRequest.predicate = predicate
        let items = try context.fetch(fetchRequest)
        
        // Delete objects
        items.forEach { context.delete($0) }
        try context.save()
        
        // Return deleted domain models objects
        return items.compactMap { T(coreDataModel: $0) }
    }
}
