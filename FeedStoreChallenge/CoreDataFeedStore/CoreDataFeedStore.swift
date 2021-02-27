//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by John Roque Jorillo on 2/27/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

public enum CoreDataStoreType {
	case disk
	case inMemory
}

public final class CoreDataFeedStore: FeedStore {
	public static let MODEL_NAME = "FeedStore"
	
	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext
	
	public init(storeURL: URL, in bundle: Bundle, of type: CoreDataStoreType = .disk) throws {
		self.container = try NSPersistentContainer.load(modelName: CoreDataFeedStore.MODEL_NAME,
														storeURL: storeURL,
														in: bundle,
														of: type)
		self.context = self.container.newBackgroundContext()
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		let context = self.context
		
		do {
			try CDFeed.find(in: context).map(context.delete).map(context.save)
			completion(nil)
		} catch {
			completion(error)
		}
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let context = self.context
		
		context.perform {
			do {
				if let oldFeed = try CDFeed.find(in: context) {
					context.delete(oldFeed)
				}
				
				let newFeed = CDFeed(context: context)
				newFeed.timestamp = timestamp
				newFeed.feedImage = CDFeedImage.toCD(images: feed, in: context)
				try context.save()
				
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		let context = self.context
		
		context.perform {
			do {
				if let feed = try CDFeed.find(in: context) {
					completion(.found(feed: feed.localFeedImage, timestamp: feed.timestamp))
				} else {
					completion(.empty)
				}
			} catch {
				completion(.failure(error))
			}
		}
	}
}

// MARK: - Models
@objc(CDFeed)
private class CDFeed: NSManagedObject {
	private static let entityName = String(describing: CDFeed.self)
	
	@NSManaged var timestamp: Date
	@NSManaged var feedImage: NSOrderedSet
	
	internal var localFeedImage: [LocalFeedImage] {
		feedImage.compactMap { ($0 as? CDFeedImage)?.localImage }
	}
	
	static internal func find(in context: NSManagedObjectContext) throws -> CDFeed? {
		let request: NSFetchRequest<CDFeed> = fetchRequest()
		return try context.fetch(request).first
	}
	
	static internal func fetchRequest() -> NSFetchRequest<CDFeed> {
		return NSFetchRequest<CDFeed>(entityName: entityName)
	}
	
}

@objc(CDFeedImage)
private class CDFeedImage: NSManagedObject {
	@NSManaged var id: UUID
	@NSManaged var desc: String?
	@NSManaged var location: String?
	@NSManaged var url: URL
	@NSManaged var feed: CDFeed
	
	internal var localImage: LocalFeedImage {
		.init(id: id, description: desc, location: location, url: url)
	}
	
	static internal func toCD(images: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
		NSOrderedSet(array: images.map { (feedImage) -> CDFeedImage in
			let cdFeedImage = CDFeedImage(context: context)
			cdFeedImage.id = feedImage.id
			cdFeedImage.desc = feedImage.description
			cdFeedImage.location = feedImage.location
			cdFeedImage.url = feedImage.url
			return cdFeedImage
		})
	}
}
