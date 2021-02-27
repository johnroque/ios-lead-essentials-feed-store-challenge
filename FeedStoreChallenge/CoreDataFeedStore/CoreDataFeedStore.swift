//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by John Roque Jorillo on 2/27/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

public final class CoreDataFeedStore: FeedStore {
	public static let MODEL_NAME = "FeedStore"
	
	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext
	
	public init(storeURL: URL, in bundle: Bundle) throws {
		self.container = try NSPersistentContainer.load(modelName: CoreDataFeedStore.MODEL_NAME,
														storeURL: storeURL,
														in: bundle)
		self.context = self.container.newBackgroundContext()
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		perform { (context) in
			do {
				try CDFeed.delete(in: context)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		perform { (context) in
			do {
				try CDFeed.insertNew(in: context,
								 feed: feed,
								 timestamp: timestamp)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		perform { (context) in
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
	
	// MARK: - Helper
	private func perform(_ block: @escaping (NSManagedObjectContext) -> Void) {
		let context = self.context
		
		context.perform {
			block(context)
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
	
	static internal func insertNew(in context: NSManagedObjectContext, feed: [LocalFeedImage], timestamp: Date) throws {
		if let oldFeed = try CDFeed.find(in: context) {
			context.delete(oldFeed)
		}
		
		let newFeed = CDFeed(context: context)
		newFeed.timestamp = timestamp
		newFeed.feedImage = CDFeedImage.toCD(images: feed, in: context)
		try context.save()
	}
	
	static internal func find(in context: NSManagedObjectContext) throws -> CDFeed? {
		let request: NSFetchRequest<CDFeed> = fetchRequest()
		return try context.fetch(request).first
	}
	
	static internal func delete(in context: NSManagedObjectContext) throws {
		try find(in: context).map(context.delete).map(context.save)
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
