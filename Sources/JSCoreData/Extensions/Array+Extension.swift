//
//  Array+Extension.swift
//  JSCoreData
//
//  Created by Jonathan Sack on 6/15/22.
//  Copyright © 2022 GHOST TECHNOLOGIES LLC. All rights reserved.
//

import CoreData

public extension Array where Element: JSCoreDataCodable {
    // Add nested CoreData models
    func addToCoreDataModels<T: JSCoreDataCodable>(
        inContext context: NSManagedObjectContext,
        using method: (T) -> ()
    ) {
        return self
            .compactMap { $0.insertCoreDataModel(inContext: context) as? T }
            .forEach { method($0) }
    }
}
