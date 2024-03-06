//
//  JSCoreDataCodable.swift
//  JSCoreData
//
//  Created by Jonathan Sack on 6/15/22.
//

import CoreData

public protocol JSCoreDataCodable: Identifiable {
    // Associated CoreData model
    associatedtype CoreDataModel: NSManagedObject, JSCoreDataEntityProtocol
    // Init from CoreData model
    init?(coreDataModel: CoreDataModel?)
    // Entity name
    static var entityName: String { get }
    // Insert CoreData model
    func insertCoreDataModel(entity: NSEntityDescription, inContext context: NSManagedObjectContext)
    func insertCoreDataModel(inContext context: NSManagedObjectContext) -> NSManagedObject
    // Set CoreData model
    func setCoreDataModel(_ coreDataModel: inout CoreDataModel, inContext context: NSManagedObjectContext)
    // Compare CoreData model
    func isEqual(to coreDataObject: CoreDataModel) -> Bool
}

public extension JSCoreDataCodable {
    static var entityName: String { return String(describing: CoreDataModel.self) }
    func insertCoreDataModel(entity: NSEntityDescription, inContext context: NSManagedObjectContext) {
        var coreDataModel = CoreDataModel(entity: entity, insertInto: context)
        setCoreDataModel(&coreDataModel, inContext: context)
    }
    func insertCoreDataModel(inContext context: NSManagedObjectContext) -> NSManagedObject {
        var coreDataModel = CoreDataModel(context: context)
        setCoreDataModel(&coreDataModel, inContext: context)
        return coreDataModel
    }
}
