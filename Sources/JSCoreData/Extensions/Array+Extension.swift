//
//  Array+Extension.swift
//  JSCoreData
//
//  Created by Jonathan Sack on 6/15/22.
//

import CoreData

public extension Array where Element: JSCoreDataCodable {
    // Add nested CoreData models
    func addToCoreDataModels<T: JSCoreDataEntityProtocol>(
        inContext context: NSManagedObjectContext,
        using method: (T) -> ()
    ) {
        return self
            .compactMap { $0.insertCoreDataModel(inContext: context) as? T }
            .forEach { method($0) }
    }
}
