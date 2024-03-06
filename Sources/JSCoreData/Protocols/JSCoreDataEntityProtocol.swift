//
//  JSCoreDataEntityProtocol.swift
//  JSCoreData
//
//  Created by Jonathan Sack on 6/15/22.
//

import CoreData

public protocol JSCoreDataEntityProtocol: NSFetchRequestResult, Equatable {
    static var entityName: String { get }
    static var sortDescriptors: [NSSortDescriptor]? { get }
}

public extension JSCoreDataEntityProtocol {
    static var entityName: String { return String(describing: self) }
    static var sortDescriptors: [NSSortDescriptor]? { return nil }
}
