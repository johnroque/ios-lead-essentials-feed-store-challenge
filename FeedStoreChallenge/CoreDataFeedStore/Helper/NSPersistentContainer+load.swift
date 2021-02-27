//
//  NSPersistentContainer+load.swift
//  FeedStoreChallenge
//
//  Created by John Roque Jorillo on 2/27/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

internal extension NSPersistentContainer {
	static func load(modelName: String, storeURL: URL, in bundle: Bundle, of type: CoreDataStoreType) throws -> NSPersistentContainer {
		guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd"),
			  let model = NSManagedObjectModel(contentsOf: modelURL) else {
			throw LoadError.invalidModel
		}
		
		let description = NSPersistentStoreDescription(url: storeURL)
		switch type {
		case .inMemory:
			description.type = NSInMemoryStoreType
		default: break
		}
		
		let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
		container.persistentStoreDescriptions = [description]
		var loadError: Swift.Error?
		container.loadPersistentStores { loadError = $1 }
		try loadError.map { _ in throw LoadError.unableToLoadPersistentStore }
		return container
	}
}

public extension NSPersistentContainer {
	enum LoadError: Swift.Error {
		case invalidModel
		case unableToLoadPersistentStore
	}
}
